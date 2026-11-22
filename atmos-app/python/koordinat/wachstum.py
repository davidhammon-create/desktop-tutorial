"""WACHSTUM - Hunger, Bedarf, Nutzungsprofil, Suche, Pruefung, Vorschlag, Entscheidung."""
import json, re, time, urllib.error
from . import algorithmen, evolution, github, module, passung, speicher, verfassung
MAX_SUCHEN, MAX_LADEN, MAX_JE_BEDARF = 3, 2, 3
HUNGER_SCHWELLE, PROFIL_SCHWELLE, MIN_SCORE, MAX_KB = 3, 5, 60, 300_000
AUTO_AN = dict(score=75, sterne=500)
OFFEN = ("gefunden", "geladen")
DE_EN = {"tabelle": "table", "rechnung": "invoice", "bild": "image", "sprache": "speech",
         "stimme": "voice", "uebersetzung": "translation", "suche": "search",
         "datenbank": "database", "texterkennung": "ocr", "agent": "agent", "agenten": "agents",
         "gedaechtnis": "memory", "auswertung": "evaluation", "lokal": "local", "modell": "model",
         "daten": "data", "datei": "file", "untertitel": "subtitles", "video": "video",
         "website": "website", "dokument": "document"}
FUELL = {"und", "oder", "fuer", "mit", "aus", "the", "for", "and", "ein", "eine", "der", "die",
         "das", "von", "in", "zu", "ich", "brauche", "will", "etwas", "wie", "kann", "man"}
THEMEN = [("Coding-Agenten", "ai-coding"), ("Coding-Agenten", "coding-agent"), ("MCP", "mcp-server"),
          ("Agenten-Frameworks", "ai-agents"), ("Lokale Modelle", "local-llm"),
          ("Lokale Modelle", "llm-inference"), ("Wissen", "rag"), ("Wissen", "vector-database"),
          ("Dokumente", "document-parsing"), ("Dokumente", "ocr"), ("Medien", "text-to-speech"),
          ("Medien", "speech-to-text"), ("Medien", "image-generation"), ("Bedienung", "browser-automation"),
          ("Bedienung", "workflow-automation"), ("Auswertung", "llm-evaluation"),
          ("Training", "fine-tuning"), ("Lernen", "awesome-list")]
PROFIL_BEDARF = {"bauen": "bausteine zum bauen finden", "pruefen": "pruefwerkzeuge und tests",
                 "schreiben": "text und entwurfshilfen", "erkunden": "suchwerkzeuge und verzeichnisse",
                 "erklaeren": "lernmaterial und beispiele"}
SEED_BEDARF = [("pdf ocr texterkennung", "pdf.scan"), ("dokumente auslesen tabellen", "dokument.lesen"),
               ("agenten framework", "agent.bauen"), ("vektordatenbank rag", "wissen.finden"),
               ("text zu sprache stimme", "medien.sprechen"), ("bild erzeugen", "medien.bild"),
               ("ablaeufe zwischen apps verbinden", "betrieb.automat"),
               ("modelle lokal starten", "modell.lokal"),
               ("untertitel sprache zu text", "medien.untertitel"),
               ("prompt auswertung messen", "qualitaet.messen")]
def anfrage(text):
    w = [DE_EN.get(x, x) for x in re.findall(r"[a-z0-9äöüß+#]+", text.lower())
         if x not in FUELL and len(x) > 1]
    return " ".join(dict.fromkeys(w))[:120]
def brauche(db, text, quelle="mensch"):
    a = anfrage(text)
    if not a:
        raise ValueError("Bedarf ist leer.")
    r = db.execute("SELECT id FROM bedarf WHERE anfrage=? AND status IN ('offen','vorgeschlagen')",
                   (a,)).fetchone()
    if r:
        return r[0]
    c = db.execute("INSERT INTO bedarf(text,anfrage,quelle,status,zeit) VALUES(?,?,?,?,?)",
                   (text, a, quelle, "offen", time.time()))
    db.commit()
    return c.lastrowid
def _hunger_zu_bedarf(db, vital):
    neu = []
    for h in vital.hunger(50):
        r = db.execute("SELECT stand FROM hunger_stand WHERE problemtyp=?", (h["problemtyp"],)).fetchone()
        if h["ungeloest"] - (r[0] if r else 0) >= HUNGER_SCHWELLE and anfrage(h["problemtyp"]):
            db.execute("INSERT OR REPLACE INTO hunger_stand VALUES(?,?)", (h["problemtyp"], h["ungeloest"]))
            brauche(db, h["problemtyp"], "hunger")
            neu.append(h["problemtyp"])
    db.commit()
    return neu
def _profil_zu_bedarf(db):
    neu = []
    for p in speicher.profil(db, 8):
        if p["anzahl"] < PROFIL_SCHWELLE or p["art"] not in PROFIL_BEDARF:
            continue
        text = PROFIL_BEDARF[p["art"]]
        if db.execute("SELECT 1 FROM bedarf WHERE text=? AND status IN ('offen','vorgeschlagen')",
                      (text,)).fetchone():
            continue
        brauche(db, text, "profil")
        neu.append(p["art"])
    return neu
def _suche(db, gh, bid, text):
    bekannt = {r[0].lower() for r in db.execute("SELECT name FROM modul UNION SELECT repo FROM vorschlag")}
    n = 0
    for t in gh.suche(text, 12, algorithmen.gewichte(db)):
        if n >= MAX_JE_BEDARF:
            break
        if (t["name"].lower() in bekannt or t["archiviert"] or t["lizenzklasse"] == "keine"
                or t["score"] < MIN_SCORE):
            continue
        db.execute("INSERT INTO vorschlag(bedarf_id,repo,score,meta,merkmale,status,grund,zeit) "
                   "VALUES(?,?,?,?,?,?,?,?)",
                   (bid, t["name"], t["score"], json.dumps(t, ensure_ascii=False),
                    json.dumps(github.merkmale(t, text)), "gefunden", "", time.time()))
        n += 1
    db.execute("UPDATE bedarf SET status=? WHERE id=?", ("vorgeschlagen" if n else "leer", bid))
    db.commit()
    return n
def _status(db, vid, status, grund):
    db.execute("UPDATE vorschlag SET status=?, grund=? WHERE id=?", (status, grund, vid))
    db.commit()
def _lade(db, vital, lader, vid, repo, text):
    try:
        man = lader(db, vital, repo, text)
    except Exception as e:
        _status(db, vid, "fehler", f"Laden gescheitert: {type(e).__name__}: {e}"[:200])
        return None
    if man["lizenzklasse"] == "keine" or man["sicherheit"] == "gesperrt":
        _status(db, vid, "gesperrt", "keine Lizenz" if man["lizenzklasse"] == "keine" else "Scan: gesperrt")
        return None
    _status(db, vid, "geladen", f"Lizenz {man['lizenz'] or '?'} ({man['lizenzklasse']}), Scan {man['sicherheit']}")
    return man
def _darf_von_selbst_an(man):
    return (man["lizenzklasse"] == "frei" and man["sicherheit"] == "bestanden"
            and man["score"] >= AUTO_AN["score"] and man["sterne"] >= AUTO_AN["sterne"])
def entdecke(db, gh=github, n_themen=1):
    zeiger, neu = int(speicher.merke(db, "themen_zeiger") or 0), []
    gew = algorithmen.gewichte(db)
    for i in range(n_themen):
        kategorie, topic = THEMEN[(zeiger + i) % len(THEMEN)]
        for t in gh.thema(topic):
            s = github.score(t, "", gew)
            if t["lizenzklasse"] == "keine" or t["archiviert"] or s < 70:
                continue
            if db.execute("SELECT 1 FROM katalog WHERE repo=? COLLATE NOCASE", (t["name"],)).fetchone():
                db.execute("UPDATE katalog SET score=?, zeit=? WHERE repo=? COLLATE NOCASE",
                           (s, time.time(), t["name"]))
            else:
                db.execute("INSERT INTO katalog VALUES(?,?,?,?,?,?,?,?,?)",
                           (t["name"], kategorie, t["beschreibung"][:90], t["sterne"], t["lizenz"],
                            t["lizenzklasse"], s, "thema:" + topic, time.time()))
                neu.append(t["name"])
    speicher.merke(db, "themen_zeiger", (zeiger + n_themen) % len(THEMEN))
    db.commit()
    return neu
def zyklus(db, vital, gh=github, lader=module.installiere):
    if verfassung.stop_gesetzt():
        return dict(status="STOP gesetzt - nichts getan")
    if vital.modus() == "sicher":
        return dict(status="Sicherer Modus - nichts getan. 'kern stand' pruefen.", modus="sicher")
    modus = vital.modus()
    b = dict(status="ok", modus=modus, hunger=[], profil=[], gesucht=[], geladen=[], eingeschaltet=[],
             gesperrt=[], stillgelegt=[], entdeckt=[], evolution={}, hinweise=[], wartet_auf_dich=0)
    vital.ruhe_abrechnen()
    for name in vital.tote():
        if db.execute("SELECT schalter FROM modul WHERE name=? AND schalter=1", (name,)).fetchone():
            module.schalte(db, vital, name, False)
            b["stillgelegt"].append(name)
    b["hunger"] = _hunger_zu_bedarf(db, vital)
    if speicher.schalter(db, "auto.profil"):
        b["profil"] = _profil_zu_bedarf(db)
    try:
        if speicher.schalter(db, "auto.suche"):
            for bid, text in db.execute("SELECT id, anfrage FROM bedarf WHERE status='offen' "
                                        "ORDER BY id LIMIT ?", (MAX_SUCHEN,)).fetchall():
                b["gesucht"].append(dict(bedarf=text, treffer=_suche(db, gh, bid, text)))
        if speicher.schalter(db, "auto.laden") and modus != "not":
            reihen = db.execute("SELECT v.id, v.repo, b.anfrage, v.meta FROM vorschlag v JOIN bedarf b "
                                "ON b.id=v.bedarf_id WHERE v.status='gefunden' ORDER BY v.score DESC").fetchall()
            geladen = 0
            for vid, repo, text, meta in reihen:
                if geladen >= MAX_LADEN or verfassung.stop_gesetzt():
                    break
                if json.loads(meta).get("groesse_kb", 0) > MAX_KB:
                    _status(db, vid, "gefunden", "zu gross fuer automatisches Laden")
                    continue
                man = _lade(db, vital, lader, vid, repo, text)
                geladen += 1
                if not man:
                    b["gesperrt"].append(repo)
                    continue
                b["geladen"].append(repo)
                if (speicher.schalter(db, "auto.einschalten") and modus == "normal"
                        and _darf_von_selbst_an(man)):
                    ok, _ = module.schalte(db, vital, man["name"], True)
                    if ok:
                        _status(db, vid, "an", "von selbst eingeschaltet")
                        b["eingeschaltet"].append(repo)
        if speicher.schalter(db, "auto.entdecken") and not verfassung.stop_gesetzt():
            b["entdeckt"] = entdecke(db, gh)
    except urllib.error.HTTPError as e:
        b["hinweise"].append("GitHub-Grenze erreicht - naechster Takt macht weiter."
                             if e.code in (403, 429) else f"GitHub-Fehler {e.code}.")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        b["hinweise"].append(f"Kein Netz: {e}"[:160])
    for name in evolution.REGISTER:
        if verfassung.stop_gesetzt():
            break
        b["evolution"][name] = evolution.schritt(db, vital, name)
    b["wartet_auf_dich"] = db.execute(
        "SELECT COUNT(*) FROM vorschlag WHERE status IN ('gefunden','geladen')").fetchone()[0]
    db.execute("INSERT INTO wachstum_log(zeit,bericht) VALUES(?,?)",
               (time.time(), json.dumps(b, ensure_ascii=False)))
    db.commit()
    return b
def erstlauf(db, vital, gh=github, lader=module.installiere):
    from . import apireg
    bericht = dict(saat=[], api=[], takt=None, fehler=[])
    for topic_kat, topic in THEMEN[:6]:
        try:
            for t in gh.thema(topic, 10):
                if db.execute("SELECT 1 FROM katalog WHERE repo=? COLLATE NOCASE", (t["name"],)).fetchone():
                    continue
                db.execute("INSERT INTO katalog VALUES(?,?,?,?,?,?,?,?,?)",
                           (t["name"], topic_kat, t["beschreibung"][:90], t["sterne"], t["lizenz"],
                            t["lizenzklasse"], github.score(t), "erstlauf", time.time()))
                bericht["saat"].append(t["name"])
        except Exception as e:
            bericht["fehler"].append(f"{topic}: {type(e).__name__}")
    db.commit()
    for text, ptyp in SEED_BEDARF:
        brauche(db, text, "erstlauf:" + ptyp)
    bericht["api"] = apireg.entdecke(db)
    bericht["takt"] = zyklus(db, vital, gh, lader)
    return bericht
def vorschlaege(db, alle=False):
    wo = "" if alle else "WHERE v.status IN ('gefunden','geladen','an')"
    return [dict(id=r[0], bedarf=r[1], quelle=r[2], repo=r[3], score=r[4], status=r[5], grund=r[6],
                 lizenz=json.loads(r[7]).get("lizenz")) for r in db.execute(
        "SELECT v.id, b.text, b.quelle, v.repo, v.score, v.status, v.grund, v.meta FROM vorschlag v "
        f"JOIN bedarf b ON b.id=v.bedarf_id {wo} ORDER BY v.score DESC")]
def _fall(db, bid, merkmale, gut):
    evolution.fall(db, "repo_score", f"bedarf:{bid}", dict(f=json.loads(merkmale), label=1 if gut else 0))
def entscheide(db, vital, vid, ja, lader=module.installiere):
    r = db.execute("SELECT v.bedarf_id, v.repo, v.status, v.merkmale, b.anfrage FROM vorschlag v "
                   "JOIN bedarf b ON b.id=v.bedarf_id WHERE v.id=?", (vid,)).fetchone()
    if not r:
        return False, "Vorschlag nicht gefunden."
    bid, repo, status, merkmale, text = r
    if status not in OFFEN + ("an",):
        return False, f"Bereits '{status}'."
    if not ja:
        _status(db, vid, "abgelehnt", "abgelehnt")
        _fall(db, bid, merkmale, False)
        return True, f"{repo} abgelehnt."
    if verfassung.stop_gesetzt():
        return False, "STOP ist gesetzt."
    if status == "gefunden" and not _lade(db, vital, lader, vid, repo, text):
        return False, db.execute("SELECT grund FROM vorschlag WHERE id=?", (vid,)).fetchone()[0]
    name = (db.execute("SELECT name FROM modul WHERE name=? COLLATE NOCASE", (repo,)).fetchone() or [repo])[0]
    ok, meldung = module.schalte(db, vital, name, True)
    if not ok:
        return False, meldung
    _status(db, vid, "an", "angenommen")
    _fall(db, bid, merkmale, True)
    db.execute("UPDATE bedarf SET status='erledigt' WHERE id=?", (bid,))
    db.commit()
    return True, f"{name} ist {meldung}"
def rueckmeldung(db, name, ergebnis):
    if ergebnis not in ("geloest", "fehler_verborgen"):
        return
    r = db.execute("SELECT bedarf_id, merkmale FROM vorschlag WHERE repo=? COLLATE NOCASE "
                   "ORDER BY id DESC LIMIT 1", (name,)).fetchone()
    if r:
        _fall(db, r[0], r[1], ergebnis == "geloest")
def dauerlauf(db, vital, takt_minuten=30, dauer_minuten=0, melde=print, schlafe=time.sleep):
    ende = time.time() + dauer_minuten * 60 if dauer_minuten else None
    while not verfassung.stop_gesetzt():
        melde(zyklus(db, vital))
        naechster = time.time() + takt_minuten * 60
        if ende and naechster > ende:
            return
        while time.time() < naechster:
            if verfassung.stop_gesetzt():
                return
            schlafe(1)
