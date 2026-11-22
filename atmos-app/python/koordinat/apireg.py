"""API-REGISTER - fremde Schnittstellen einordnen, nach Kosten sortieren, Budget halten.
Vier Stufen: 0 lokal/gratis, 1 unter einem Cent, 2 Euro-Bereich, 3 deutlich darueber.
Schluessel stehen in der Umgebung, nie in der Datenbank. R9: bei Rot gewinnt die
billigste ausreichende Stufe, nicht Abbruch.
"""
import os, time
from . import speicher
STUFEN = {0: ("lokal", "gratis, eigenes Geraet"), 1: ("cent", "unter 1 Cent je Aufruf"),
          2: ("euro", "Euro-Bereich je Aufruf"), 3: ("teuer", "deutlich ueber 1 Euro je Aufruf")}
FAEHIGKEITEN = ("text", "bild", "video", "tts", "stt", "embedding", "ocr", "suche")
SAAT = [
    ("ollama", "text", 0, 0.0, "Aufruf", "OLLAMA_HOST"),
    ("llama.cpp", "text", 0, 0.0, "Aufruf", ""),
    ("whisper-lokal", "stt", 0, 0.0, "Minute", ""),
    ("tesseract", "ocr", 0, 0.0, "Seite", ""),
    ("sentence-transformers", "embedding", 0, 0.0, "Aufruf", ""),
    ("groq-llama", "text", 1, 0.08, "1k Token", "GROQ_API_KEY"),
    ("deepinfra-mixtral", "text", 1, 0.15, "1k Token", "DEEPINFRA_API_KEY"),
    ("together-qwen", "text", 1, 0.20, "1k Token", "TOGETHER_API_KEY"),
    ("gemini-flash", "text", 1, 0.30, "1k Token", "GOOGLE_API_KEY"),
    ("gpt-4o-mini", "text", 1, 0.45, "1k Token", "OPENAI_API_KEY"),
    ("flux-schnell", "bild", 1, 0.90, "Bild", "REPLICATE_API_TOKEN"),
    ("elevenlabs-tts", "tts", 2, 2.50, "1k Zeichen", "ELEVENLABS_API_KEY"),
    ("whisper-api", "stt", 2, 6.00, "Minute", "OPENAI_API_KEY"),
    ("gpt-4o", "text", 2, 7.00, "1k Token", "OPENAI_API_KEY"),
    ("claude-sonnet", "text", 2, 9.00, "1k Token", "ANTHROPIC_API_KEY"),
    ("runway", "video", 3, 45.00, "Clip", "RUNWAY_API_KEY"),
    ("sora", "video", 3, 60.00, "Clip", "OPENAI_API_KEY"),
]
def eintragen(db, name, faehigkeit, stufe, preis_cent, einheit="Aufruf", env="", quelle="mensch"):
    if faehigkeit not in FAEHIGKEITEN:
        raise ValueError(f"unbekannte Faehigkeit: {faehigkeit}")
    if stufe not in STUFEN:
        raise ValueError("Stufe muss 0..3 sein.")
    if preis_cent < 0:
        raise ValueError("Preis darf nicht negativ sein.")
    db.execute("INSERT OR REPLACE INTO api(name,faehigkeit,stufe,preis_cent,einheit,env,schalter,"
               "quelle,notiz,zeit) VALUES(?,?,?,?,?,?,COALESCE((SELECT schalter FROM api WHERE name=?),0),"
               "?,?,?)",
               (name, faehigkeit, stufe, float(preis_cent), einheit, env, name, quelle, "", time.time()))
    db.commit()
    return dict(name=name, faehigkeit=faehigkeit, stufe=stufe, preis_cent=preis_cent)
def entdecke(db):
    neu = []
    for name, f, st, p, e, env in SAAT:
        if not db.execute("SELECT 1 FROM api WHERE name=?", (name,)).fetchone():
            eintragen(db, name, f, st, p, e, env, "saat")
            neu.append(name)
    return neu
def schalte(db, name, an):
    r = db.execute("SELECT stufe, env FROM api WHERE name=?", (name,)).fetchone()
    if not r:
        raise LookupError("Anbieter nicht bekannt.")
    if an and r[0] > 0 and r[1] and not os.environ.get(r[1]):
        return False, f"Geschaltet, aber {r[1]} fehlt in der Umgebung."
    db.execute("UPDATE api SET schalter=? WHERE name=?", (1 if an else 0, name))
    db.commit()
    return True, "AN." if an else "AUS."
def monat_cent(db):
    r = db.execute("SELECT COALESCE(SUM(cent),0) FROM kosten_log WHERE zeit >= ?",
                   (time.time() - 31 * 86400,)).fetchone()
    return float(r[0])
def ampel(db):
    b = speicher.budget(db)
    if b <= 0:
        return "leer"
    q = monat_cent(db) / b
    return "gruen" if q < 0.5 else "gelb" if q < 0.85 else "rot"
def liste(db, faehigkeit=None):
    wo, args = ("WHERE faehigkeit=?", (faehigkeit,)) if faehigkeit else ("", ())
    return [dict(name=r[0], faehigkeit=r[1], stufe=r[2], preis_cent=r[3], einheit=r[4],
                 an=bool(r[5]), env=r[6]) for r in db.execute(
        f"SELECT name,faehigkeit,stufe,preis_cent,einheit,schalter,env FROM api {wo} "
        "ORDER BY stufe, preis_cent", args)]
def waehle(db, faehigkeit, stufe_max=None):
    a = ampel(db)
    deckel = 1 if a in ("rot", "leer") else 3
    if stufe_max is not None:
        deckel = min(deckel, stufe_max)
    for e in liste(db, faehigkeit):
        if e["an"] and e["stufe"] <= deckel:
            return e
    return None
def verbrauch(db, vital, name, einheiten=1.0, zweck=""):
    r = db.execute("SELECT stufe, preis_cent FROM api WHERE name=?", (name,)).fetchone()
    if not r:
        raise LookupError("Anbieter nicht bekannt.")
    if ampel(db) == "rot" and r[0] >= 2:
        return False, "Ampel rot: Stufe zu teuer. Billiger waehlen oder Budget erhoehen."
    cent = r[1] * float(einheiten)
    db.execute("INSERT INTO kosten_log(zeit,api,einheiten,cent,zweck) VALUES(?,?,?,?,?)",
               (time.time(), name, float(einheiten), cent, zweck))
    db.commit()
    vital.buche("api:" + name, "kosten_cent", cent, problemtyp="kosten")
    return True, f"{cent:.2f} Cent gebucht ({ampel(db)})."
def bericht(db):
    z = [f"Ampel: {ampel(db)}   Budget: {speicher.budget(db) / 100:.2f} EUR   "
         f"verbraucht: {monat_cent(db) / 100:.2f} EUR"]
    for e in liste(db):
        z.append(f"  Stufe {e['stufe']} {e['name']:<24} {e['preis_cent']:.2f} Cent/{e['einheit']:<10} "
                 f"{'AN' if e['an'] else 'aus'}")
    return "\n".join(z)
