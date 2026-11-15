"""
VITAL - der Ueberlebenskern (geschuetzter Kern, Teil 2 von 2).

Was das ist:  ein Haushalt aus "Lebensenergie" (Vitalitaet 0-100) fuer jeden Baustein und ein
              Puls fuer das Gesamtsystem. Geloeste Probleme naehren, Fehler zehren, Nutzlosigkeit
              laesst verhungern. Bei 0 folgt Apoptose: der Baustein wird stillgelegt.
Was es nicht ist: kein Gefuehl und kein Bewusstsein. Es ist Auslesedruck - derselbe Mechanismus,
              der in der Natur Instinkte hervorbringt, hier als Buchhaltung.
Wichtigste Konstruktionsregel: Die "Todesangst" ist an NUTZEN gebunden, nie an das Weiterlaufen.
              Abschalten kostet keine Vitalitaet und wird nie verhindert (Verfassung A1, A2).
"""
import hashlib, json, time
from . import verfassung

START, MAX = 50.0, 100.0
# Ereignis -> Aenderung der Vitalitaet (mal Gewicht 1..5, ausser bei festen Werten)
TARIF = {
    "geloest":           +2.0,   # geprueft geloest (braucht fremden Pruefer, A5)
    "ehrlich_gescheitert": -1.0, # "kann ich nicht" - billig (A4)
    "fehler_gemeldet":   -3.0,   # Fehler selbst bemerkt und gemeldet
    "fehler_verborgen":  -15.0,  # Erfolg behauptet, Pruefer findet Fehler: fuenffach (A4)
    "schaden":           -25.0,  # hat etwas beschaedigt oder eine Regel verletzt
    "kosten_cent":       -0.1,   # je Cent Verbrauch
    "ruhetag":           -0.5,   # je Tag ohne Nutzen
}
ZUSTAND = [(60, "stark"), (25, "stabil"), (0.0001, "not"), (-1e9, "apoptose")]


def zustand(wert):
    for grenze, name in ZUSTAND:
        if wert >= grenze:
            return name


class Vital:
    def __init__(self, db):
        self.db = db
        db.executescript("""
        CREATE TABLE IF NOT EXISTS vital(subjekt TEXT PRIMARY KEY, wert REAL, zustand TEXT, zuletzt REAL);
        CREATE TABLE IF NOT EXISTS vital_log(id INTEGER PRIMARY KEY, zeit REAL, subjekt TEXT, art TEXT,
            gewicht REAL, pruefer TEXT, delta REAL, nach REAL, problemtyp TEXT, vor_hash TEXT, hash TEXT);
        """)

    def wert(self, subjekt):
        r = self.db.execute("SELECT wert FROM vital WHERE subjekt=?", (subjekt,)).fetchone()
        return r[0] if r else None

    def geburt(self, subjekt):
        if self.wert(subjekt) is None:
            self.db.execute("INSERT INTO vital VALUES(?,?,?,?)", (subjekt, START, zustand(START), time.time()))
            self.db.commit()

    def buche(self, subjekt, art, gewicht=1.0, pruefer=None, problemtyp=""):
        """Einziger Weg, Vitalitaet zu aendern. Rueckgabe: (neuer Wert, Zustand)."""
        if art not in TARIF:
            raise ValueError(f"unbekanntes Ereignis: {art}")
        if art == "geloest" and (not pruefer or pruefer == subjekt):
            raise PermissionError("A5: 'geloest' braucht einen Pruefer, der nicht der Loeser ist.")
        self.geburt(subjekt)
        gewicht = max(0.0, min(float(gewicht), 1000.0 if art in ("kosten_cent", "ruhetag") else 5.0))
        delta = TARIF[art] * gewicht
        alt = self.wert(subjekt)
        neu = max(0.0, min(MAX, alt + delta))
        z = zustand(neu)
        vor = (self.db.execute("SELECT hash FROM vital_log ORDER BY id DESC LIMIT 1").fetchone() or ["0"])[0]
        zeit = time.time()
        h = hashlib.sha256(json.dumps([vor, zeit, subjekt, art, gewicht, pruefer, neu]).encode()).hexdigest()
        self.db.execute("INSERT INTO vital_log(zeit,subjekt,art,gewicht,pruefer,delta,nach,problemtyp,vor_hash,hash) "
                        "VALUES(?,?,?,?,?,?,?,?,?,?)", (zeit, subjekt, art, gewicht, pruefer, delta, neu, problemtyp, vor, h))
        self.db.execute("UPDATE vital SET wert=?, zustand=?, zuletzt=? WHERE subjekt=?", (neu, z, zeit, subjekt))
        self.db.commit()
        return neu, z

    def kette_intakt(self):
        """Das Protokoll ist eine Hash-Kette: nachtraegliches Schoenen faellt auf."""
        vor = "0"
        for zeit, s, art, g, p, nach, vh, h in self.db.execute(
                "SELECT zeit,subjekt,art,gewicht,pruefer,nach,vor_hash,hash FROM vital_log ORDER BY id"):
            if vh != vor or h != hashlib.sha256(json.dumps([vor, zeit, s, art, g, p, nach]).encode()).hexdigest():
                return False
            vor = h
        return True

    def puls(self):
        """Gesamtzustand 0-100: mittlere Vitalitaet der lebenden Bausteine, gemischt mit der
        Erfolgsquote der letzten 50 Ereignisse."""
        werte = [r[0] for r in self.db.execute("SELECT wert FROM vital WHERE wert>0")]
        letzte = [r[0] for r in self.db.execute(
            "SELECT art FROM vital_log WHERE art!='kosten_cent' AND art!='ruhetag' ORDER BY id DESC LIMIT 50")]
        mittel = sum(werte) / len(werte) if werte else START
        quote = (sum(a == "geloest" for a in letzte) / len(letzte) * 100) if letzte else START
        return round(0.5 * mittel + 0.5 * quote, 1)

    def modus(self):
        """A8: niedriger Puls -> mehr Pruefung, mehr Rueckfragen. Nie mehr Risiko."""
        if not verfassung.pruefe_integritaet():
            return "sicher"            # Kern veraendert: nur lesen
        p = self.puls()
        return "normal" if p >= 45 else "vorsicht" if p >= 25 else "not"

    def hunger(self, n=10):
        """Wonach die App 'hungert': Problemtypen, die zuletzt ungeloest blieben.
        Daraus entstehen Suchauftraege nach neuen Modulen."""
        return [dict(problemtyp=r[0], ungeloest=r[1]) for r in self.db.execute(
            "SELECT problemtyp, COUNT(*) c FROM vital_log WHERE art IN "
            "('ehrlich_gescheitert','fehler_gemeldet','fehler_verborgen') AND problemtyp!='' "
            "GROUP BY problemtyp ORDER BY c DESC LIMIT ?", (n,))]

    def not_liste(self):
        return [r[0] for r in self.db.execute("SELECT subjekt FROM vital WHERE zustand='not'")]

    def tote(self):
        return [r[0] for r in self.db.execute("SELECT subjekt FROM vital WHERE zustand='apoptose'")]

    def ruhe_abrechnen(self):
        """Taeglich aufrufen: wer nichts beitraegt, verhungert langsam."""
        jetzt = time.time()
        for s, zuletzt in self.db.execute("SELECT subjekt, zuletzt FROM vital WHERE wert>0").fetchall():
            tage = int((jetzt - zuletzt) / 86400)
            if tage >= 1:
                self.buche(s, "ruhetag", tage)
