"""WACHSTUM - die Schleife, mit der die App sich selbst erweitert (Band III, Kap. 5, Schritte 6 -> 10).

    Hunger / Bedarf -> Suche auf GitHub -> Bewerten -> Laden + Lizenz + Risiko -> Vorschlag -> (Einschalten)
          ^                                                                             |
          +---------- Rueckmeldung (annehmen, ablehnen, geloest, Fehler) --------------+
                      naehrt Vitalitaet UND die Lernfaelle der Algorithmen

Ein Aufruf von zyklus() ist ein Takt. Was er selbstaendig tun darf, bestimmen die Schalter (speicher.SCHALTER)
und der Zustand der App:
    STOP gesetzt      nichts (A1)
    Modus sicher      nichts (Kern-Siegel stimmt nicht)
    Modus not         nur suchen und vorschlagen
    Modus vorsicht    suchen, laden, pruefen - aber nichts von selbst einschalten, keine Experimente (A8)
    Modus normal      alles, was die Schalter erlauben
Fremder Code wird nie ausgefuehrt (A7); nichts wird geloescht (A6). Jeder Takt hat feste Obergrenzen.
"""
import json, re, time, urllib.error
from . import algorithmen, evolution, github, module, speicher, verfassung

MAX_SUCHEN, MAX_LADEN, MAX_JE_BEDARF = 3, 2, 3          # Obergrenzen je Takt
HUNGER_SCHWELLE, MIN_SCORE, MAX_KB = 3, 60, 300_000
AUTO_AN = dict(score=75, sterne=500)                     # Mindestwerte fuer selbstaendiges Einschalten
OFFEN = ("gefunden", "geladen")

# Deutsch -> Suchsprache von GitHub. Bewusst klein; waechst spaeter ueber ein Modell (Band III, Kap. 8).
DE_EN = {"tabelle": "table", "tabellen": "table", "rechnung": "invoice", "rechnungen": "invoice", "bild": "image",
         "bilder": "image", "sprache": "speech", "stimme": "voice", "uebersetzung": "translation", "übersetzung": "translation",
         "zusammenfassung": "summarization", "suche": "search", "datenbank": "database", "webseite": "website",
         "texterkennung": "ocr", "scan": "ocr", "handschrift": "handwriting", "erkennung": "recognition",
         "diagramm": "chart", "kalender": "calendar", "tabellenkalkulation": "spreadsheet", "agent": "agent",
         "agenten": "agents", "gedaechtnis": "memory", "gedächtnis": "memory", "auswertung": "evaluation",
         "untertitel": "subtitles", "musik": "music", "pruefen": "validation", "prüfen": "validation",
         "lokal": "local", "modell": "model", "modelle": "models", "daten": "data", "datei": "file", "dateien": "files"}
FUELL = {"und", "oder", "fuer", "für", "mit", "aus", "the", "for", "and", "ein", "eine", "einen", "der", "die", "das",
         "von", "in", "zu", "ich", "brauche", "will", "moechte", "möchte", "etwas", "was", "wie", "kann", "man", "mein",
         "meine", "meiner", "a", "an", "to", "of", "ersatz"}

# Themen, aus denen der Katalog selbstaendig waechst (GitHub-Topics)
THEMEN = [("Coding-Agenten", "ai-coding"), ("Coding-Agenten", "coding-agent"), ("MCP", "mcp-server"),
          ("MCP", "model-context-protocol"), ("Agenten-Frameworks", "ai-agents"), ("Agenten-Frameworks", "multi-agent"),
          ("Lokale Modelle", "local-llm"), ("Lokale Modelle", "llm-inference"), ("Wissen", "rag"),
          ("Wissen", "vector-database"), ("Dokumente", "document-parsing"), ("Dokumente", "ocr"),
          ("Medien", "text-to-speech"), ("Medien", "speech-to-text"), ("Medien", "image-generation"),
          ("Bedienung", "browser-automation"), ("Bedienung", "workflow-automation"), ("Prompts", "prompt-engineering"),
          ("Auswertung", "llm-evaluation"), ("Training", "fine-tuning"), ("Lernen", "awesome-list")]


def anfrage(text):
    """Macht aus einem Bedarf in Alltagssprache oder einem Problemtyp ('pdf.scan') eine GitHub-Suchanfrage."""
    w = [DE_EN.get(x, x) for x in re.findall(r"[a-z0-9äöüß+#]+", text.lower()) if x not in FUELL and len(x) > 1]
    return " ".join(dict.fromkeys(w))[:120]


def brauche(db, text, quelle="mensch"):
    """Meldet einen Bedarf an. Der naechste Takt sucht dafuer. Gleiche offene Bedarfe werden nicht verdoppelt."""
    a = anfrage(text)
    if not a:
        raise ValueError("Bedarf ist leer.")
    r = db.execute("SELECT id FROM bedarf WHERE anfrage=? AND status IN ('offen','vorgeschlagen')", (a,)).fetchone()
    if r:
        return r[0]
    c = db.execute("INSERT INTO bedarf(text,anfrage,quelle,status,zeit) VALUES(?,?,?,?,?)", (text, a, quelle, "offen", time.time()))
    db.commit()
    return c.lastrowid


def _hunger_zu_bedarf(db, vital):
    """Je HUNGER_SCHWELLE neue gescheiterte Faelle eines Problemtyps entsteht ein Suchauftrag."""
    neu = []
    for h in vital.hunger(50):
        r = db.execute("SELECT stand FROM hunger_stand WHERE problemtyp=?", (h["problemtyp"],)).fetchone()
        if h["ungeloest"] - (r[0] if r else 0) >= HUNGER_SCHWELLE and anfrage(h["problemtyp"]):
            db.execute("INSERT OR REPLACE INTO hunger_stand VALUES(?,?)", (h["problemtyp"], h["ungeloest"]))
            brauche(db, h["problemtyp"], "hunger")
            neu.append(h["problemtyp"])
    db.commit()
    return neu


def _suche(db, gh, bid, text):
    bekannt = {r[0].lower() for r in db.execute("SELECT name FROM modul UNION SELECT repo FROM vorschlag")}
    n = 0
    for t in gh.suche(text, 12, algorithmen.gewichte(db)):
        if n >= MAX_JE_BEDARF:
            break
        if t["name"].lower() in bekannt or t["archiviert"] or t["lizenzklasse"] == "keine" or t["score"] < MIN_SCORE:
            continue
        db.execute("INSERT INTO vorschlag(bedarf_id,repo,score,meta,merkmale,status,grund,zeit) VALUES(?,?,?,?,?,?,?,?)",
                   (bid, t["name"], t["score"], json.dumps(t, ensure_ascii=False), json.dumps(github.merkmale(t, text)),
                    "gefunden", "", time.time()))
        n += 1
    db.execute("UPDATE bedarf SET status=? WHERE id=?", ("vorgeschlagen" if n else "leer", bid))
    db.commit()
    return n


def _status(db, vid, status, grund):
    db.execute("UPDATE vorschlag SET status=?, grund=? WHERE id=?", (status, grund, vid))
    db.commit()


def _lade(db, vital, lader, vid, repo, text):
    """Laden + Lizenz + Risiko. Rueckgabe: Manifest oder None. Das Modul bleibt AUS."""
    try:
        man = lader(db, vital, repo, text)
    except Exception as e:
        _status(db, vid, "fehler", f"Laden gescheitert: {type(e).__name__}: {e}"[:200])
        return None
    if man["lizenzklasse"] == "keine" or man["sicherheit"] == "gesperrt":
        _status(db, vid, "gesperrt", "keine Lizenz" if man["lizenzklasse"] == "keine" else
                "Sicherheitsscan: " + "; ".join(b["befund"] for b in man["befunde"] if b["stufe"] == "hoch")[:160])
        return None
    _status(db, vid, "geladen", f"Lizenz {man['lizenz'] or '?'} ({man['lizenzklasse']}), Scan {man['sicherheit']}")
    return man


def _darf_von_selbst_an(man):
    return (man["lizenzklasse"] == "frei" and man["sicherheit"] == "bestanden" and man["score"] >= AUTO_AN["score"]
            and man["sterne"] >= AUTO_AN["sterne"])


def entdecke(db, gh=github, n_themen=1):
    """Laesst den Katalog wachsen: je Takt ein Thema, reihum. Nur lizenzierte, gepflegte Projekte."""
    zeiger, neu = int(speicher.merke(db, "themen_zeiger") or 0), []
    gew = algorithmen.gewichte(db)
    for i in range(n_themen):
        kategorie, topic = THEMEN[(zeiger + i) % len(THEMEN)]
        for t in gh.thema(topic):
            s = github.score(t, "", gew)
            if t["lizenzklasse"] == "keine" or t["archiviert"] or s < 70:
                continue
            if db.execute("SELECT 1 FROM katalog WHERE repo=? COLLATE NOCASE", (t["name"],)).fetchone():
                db.execute("UPDATE katalog SET sterne=?, lizenz=?, lizenzklasse=?, score=?, zeit=? WHERE repo=? COLLATE NOCASE",
                           (t["sterne"], t["lizenz"], t["lizenzklasse"], s, time.time(), t["name"]))
            else:
                db.execute("INSERT INTO katalog VALUES(?,?,?,?,?,?,?,?,?)", (t["name"], kategorie, t["beschreibung"][:90],
                           t["sterne"], t["lizenz"], t["lizenzklasse"], s, "thema:" + topic, time.time()))
                neu.append(t["name"])
    speicher.merke(db, "themen_zeiger", (zeiger + n_themen) % len(THEMEN))
    db.commit()
    return neu


def zyklus(db, vital, gh=github, lader=module.installiere):
    """Ein Takt der Wachstumsschleife. Rueckgabe: Bericht (dict), wird auch im Protokoll abgelegt."""
    if verfassung.stop_gesetzt():
        return dict(status="STOP gesetzt - nichts getan")
    modus = vital.modus()
    if modus == "sicher":
        return dict(status="Sicherer Modus (Kern-Siegel stimmt nicht) - nichts getan", modus=modus)
    b = dict(status="ok", modus=modus, hunger=[], gesucht=[], geladen=[], eingeschaltet=[], gesperrt=[],
             stillgelegt=[], entdeckt=[], evolution={}, hinweise=[])

    # Haushalt: Ruhetage abrechnen, Gestorbene ausschalten, fuer Module in Not einen Nachfolger suchen
    vital.ruhe_abrechnen()
    for name in vital.tote():
        if db.execute("SELECT schalter FROM modul WHERE name=? AND schalter=1", (name,)).fetchone():
            module.schalte(db, vital, name, False)
            b["stillgelegt"].append(name)
    b["hunger"] = _hunger_zu_bedarf(db, vital)
    for name in vital.not_liste():
        r = db.execute("SELECT beschreibung FROM modul WHERE name=? AND schalter=1", (name,)).fetchone()
        if r and r[0] and anfrage(r[0]):
            brauche(db, " ".join(r[0].split()[:6]), "not:" + name)

    try:
        # Suchen
        if speicher.schalter(db, "auto.suche"):
            for bid, text in db.execute("SELECT id, anfrage FROM bedarf WHERE status='offen' ORDER BY id LIMIT ?", (MAX_SUCHEN,)).fetchall():
                b["gesucht"].append(dict(bedarf=text, treffer=_suche(db, gh, bid, text)))
        # Laden und pruefen (nicht im Notmodus: dann nur vorschlagen)
        if speicher.schalter(db, "auto.laden") and modus != "not":
            # je Takt die besten offenen Treffer, aber zuerst je Bedarf der beste
            reihen = db.execute("SELECT v.id, v.repo, b.anfrage, v.meta FROM vorschlag v JOIN bedarf b ON b.id=v.bedarf_id "
                                "WHERE v.status='gefunden' ORDER BY (SELECT COUNT(*) FROM vorschlag w WHERE w.bedarf_id=v.bedarf_id "
                                "AND w.status IN ('geladen','an')), v.score DESC").fetchall()
            geladen = 0
            for vid, repo, text, meta in reihen:
                if geladen >= MAX_LADEN or verfassung.stop_gesetzt():
                    break
                if json.loads(meta).get("groesse_kb", 0) > MAX_KB:
                    _status(db, vid, "gefunden", "zu gross fuer selbstaendiges Laden - bei Bedarf von Hand annehmen")
                    continue
                man = _lade(db, vital, lader, vid, repo, text)
                geladen += 1
                if not man:
                    b["gesperrt"].append(repo)
                    continue
                b["geladen"].append(repo)
                if speicher.schalter(db, "auto.einschalten") and modus == "normal" and _darf_von_selbst_an(man):
                    ok, _ = module.schalte(db, vital, man["name"], True)
                    if ok:
                        _status(db, vid, "an", f"von selbst eingeschaltet: freie Lizenz, Scan bestanden, Score {man['score']}")
                        b["eingeschaltet"].append(repo)
        # Katalog wachsen lassen
        if speicher.schalter(db, "auto.entdecken") and not verfassung.stop_gesetzt():
            b["entdeckt"] = entdecke(db, gh)
    except urllib.error.HTTPError as e:
        b["hinweise"].append("GitHub-Abfragegrenze erreicht - naechster Takt macht weiter (GITHUB_TOKEN hebt die Grenze)."
                             if e.code in (403, 429) else f"GitHub antwortet mit Fehler {e.code}.")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        b["hinweise"].append(f"Kein Netz zu GitHub: {e}"[:160])

    # Eigene Algorithmen nachstellen (ohne Netz, nur Zahlen - siehe evolution.py)
    for name in evolution.REGISTER:
        if verfassung.stop_gesetzt():
            break
        b["evolution"][name] = evolution.schritt(db, vital, name)

    b["wartet_auf_dich"] = db.execute("SELECT COUNT(*) FROM vorschlag WHERE status IN ('gefunden','geladen')").fetchone()[0]
    db.execute("INSERT INTO wachstum_log(zeit,bericht) VALUES(?,?)", (time.time(), json.dumps(b, ensure_ascii=False)))
    db.commit()
    return b


def vorschlaege(db, alle=False):
    wo = "" if alle else "WHERE v.status IN ('gefunden','geladen','an')"
    return [dict(id=r[0], bedarf=r[1], quelle=r[2], repo=r[3], score=r[4], status=r[5], grund=r[6],
                 sterne=json.loads(r[7]).get("sterne"), lizenz=json.loads(r[7]).get("lizenz"),
                 beschreibung=json.loads(r[7]).get("beschreibung", "")) for r in db.execute(
        "SELECT v.id, b.text, b.quelle, v.repo, v.score, v.status, v.grund, v.meta FROM vorschlag v "
        f"JOIN bedarf b ON b.id=v.bedarf_id {wo} ORDER BY v.bedarf_id DESC, v.score DESC")]


def _fall(db, bid, merkmale, gut):
    evolution.fall(db, "repo_score", f"bedarf:{bid}", dict(f=json.loads(merkmale), label=1 if gut else 0))


def entscheide(db, vital, vid, ja, lader=module.installiere):
    """Der Mensch nimmt einen Vorschlag an oder lehnt ihn ab. Beides ist ein Lernfall fuer die Bewertung.
    Annehmen schaltet das Modul ein (laedt es vorher, falls noetig); die uebrigen offenen Vorschlaege
    desselben Bedarfs gelten als uebergangen."""
    r = db.execute("SELECT v.bedarf_id, v.repo, v.status, v.merkmale, b.anfrage FROM vorschlag v JOIN bedarf b "
                   "ON b.id=v.bedarf_id WHERE v.id=?", (vid,)).fetchone()
    if not r:
        return False, "Vorschlag nicht gefunden."
    bid, repo, status, merkmale, text = r
    if status not in OFFEN + ("an",):
        return False, f"Vorschlag ist bereits '{status}'."
    if not ja:
        _status(db, vid, "abgelehnt", "vom Menschen abgelehnt")
        _fall(db, bid, merkmale, False)
        if status == "an":
            module.schalte(db, vital, repo, False)
        return True, f"{repo} abgelehnt. (Bleibt archiviert, nichts wird geloescht.)"
    if verfassung.stop_gesetzt():
        return False, "STOP ist gesetzt."
    if status == "gefunden" and not _lade(db, vital, lader, vid, repo, text):
        return False, db.execute("SELECT grund FROM vorschlag WHERE id=?", (vid,)).fetchone()[0]
    name = (db.execute("SELECT name FROM modul WHERE name=? COLLATE NOCASE", (repo,)).fetchone() or [repo])[0]
    ok, meldung = module.schalte(db, vital, name, True)
    if not ok:
        return False, meldung
    _status(db, vid, "an", "vom Menschen angenommen")
    _fall(db, bid, merkmale, True)
    for wid, wm in db.execute("SELECT id, merkmale FROM vorschlag WHERE bedarf_id=? AND id!=? AND status IN ('gefunden','geladen')",
                              (bid, vid)).fetchall():
        _status(db, wid, "uebergangen", "ein anderer Vorschlag wurde angenommen")
        _fall(db, bid, wm, False)
    db.execute("UPDATE bedarf SET status='erledigt' WHERE id=?", (bid,))
    db.commit()
    return True, f"{name} ist {meldung}"


def rueckmeldung(db, name, ergebnis):
    """Nach 'melde': bewaehrt sich ein vorgeschlagenes Modul, lernt die Bewertung daraus."""
    if ergebnis not in ("geloest", "fehler_verborgen"):
        return
    r = db.execute("SELECT bedarf_id, merkmale FROM vorschlag WHERE repo=? COLLATE NOCASE ORDER BY id DESC LIMIT 1", (name,)).fetchone()
    if r:
        _fall(db, r[0], r[1], ergebnis == "geloest")


def dauerlauf(db, vital, takt_minuten=30, dauer_minuten=0, melde=print, schlafe=time.sleep):
    """Wiederholt zyklus(). Prueft die Stop-Marke jede Sekunde (A1) und endet sofort, wenn sie gesetzt ist."""
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
