"""LEITFADEN - der gefuehrte Ablauf. Kein blosser Nachschlagetext, sondern Schritt-fuer-Schritt:
Wer ein Anliegen eintippt ("KI-Video erstellen", "Firma automatisieren", "besseren Agenten bauen",
"wie funktioniert GitHub"), wird sofort durch einen Ablauf geleitet - ein Schritt nach dem anderen,
mit genau dem Werkzeug, das dieser Schritt braucht.

Die Inhalte stehen in leitfaden.json (ein Block je Ablauf) und lassen sich ohne Programmierung
erweitern. Jeder Ablauf hat Schritte; ein Schritt kann auf ein Werkzeug zeigen (koordinat_suche,
koordinat_guide ...) und auf empfohlene Katalog-Projekte. Der Stand (welcher Schritt) wird je Ablauf
in der Datenbank gemerkt, damit "weiter" dort anknuepft, wo man war.

Ausloeser:
  - Mensch:  koordinat los "<anliegen>"   -> passenden Ablauf starten, Schritt 1 zeigen
             koordinat weiter-im-leitfaden -> naechster Schritt
  - KI/MCP:  koordinat_los {anliegen}      -> die KI bekommt den Ablauf als Plan und fuehrt ihn aus
"""
import json, pathlib, re, time

_DATEI = pathlib.Path(__file__).parent / "leitfaden.json"


def ablaeufe():
    return json.loads(_DATEI.read_text())


def _norm(t):
    t = t.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        t = t.replace(a, b)
    return t


def finde(anliegen):
    """Waehlt den am besten passenden Ablauf zum Anliegen (Alltagssprache). None, wenn keiner passt."""
    ws = [w for w in re.findall(r"[a-z0-9+#]+", _norm(anliegen)) if len(w) > 2]
    if not ws:
        return None
    best, bp = None, 0
    for a in ablaeufe():
        heu = _norm(" ".join(a["ausloeser"]))
        titel = _norm(a["titel"])
        p = sum(4 * (w in heu.split()) + 2 * (w in heu) + 3 * (w in titel) for w in ws)
        if p > bp:
            best, bp = a, p
    return best if bp >= 4 else None


def _ablauf(kennung):
    return next((a for a in ablaeufe() if a["id"] == kennung), None)


def _schritt_text(a, i, mit_werkzeug=True):
    s = a["schritte"][i]
    kopf = f"[{a['titel']}]  Schritt {i + 1} von {len(a['schritte'])}: {s['titel']}"
    zeilen = [kopf, "-" * len(kopf), s["text"].strip()]
    if s.get("tipp"):
        zeilen.append("Tipp: " + s["tipp"])
    if mit_werkzeug and s.get("werkzeug"):
        zeilen.append("Werkzeug: " + s["werkzeug"])
    if s.get("projekte"):
        zeilen.append("Empfohlen aus dem Katalog: " + ", ".join(s["projekte"]))
    if s.get("befehl"):
        zeilen.append("Befehl: " + s["befehl"])
    rest = len(a["schritte"]) - i - 1
    zeilen.append(f"\n-> 'koordinat weiter' fuer den naechsten Schritt." if rest else
                  "\n-> Das war der letzte Schritt. Viel Erfolg. 'koordinat los \"...\"' startet den naechsten Ablauf.")
    return "\n".join(zeilen)


def los(db, anliegen):
    """Startet den passenden Ablauf und gibt Schritt 1 zurueck (Text). Merkt den Stand."""
    a = finde(anliegen)
    if not a:
        titel = ", ".join(x["titel"] for x in ablaeufe())
        return (f"Zu '{anliegen}' habe ich noch keinen gefuehrten Ablauf. Vorhanden: {titel}.\n"
                f"Fuer einzelne Begriffe hilft 'koordinat guide <begriff>'. "
                f"Oder 'koordinat brauche \"{anliegen}\"', damit die App ein Projekt dafuer sucht.")
    db.execute("INSERT OR REPLACE INTO leitfaden_stand VALUES(?,?,?)", (a["id"], 0, time.time()))
    db.commit()
    db.execute("INSERT OR REPLACE INTO einstellung VALUES('_leitfaden_aktiv', ?)", (a["id"],))
    db.commit()
    return _schritt_text(a, 0)


def weiter(db):
    """Naechster Schritt des zuletzt gestarteten Ablaufs."""
    r = db.execute("SELECT wert FROM einstellung WHERE name='_leitfaden_aktiv'").fetchone()
    if not r or not _ablauf(r[0]):
        return "Kein Ablauf laeuft gerade. Starte einen mit 'koordinat los \"<anliegen>\"'."
    a = _ablauf(r[0])
    st = db.execute("SELECT schritt FROM leitfaden_stand WHERE ablauf=?", (a["id"],)).fetchone()
    i = (st[0] if st else 0) + 1
    if i >= len(a["schritte"]):
        db.execute("DELETE FROM einstellung WHERE name='_leitfaden_aktiv'")
        db.commit()
        return f"[{a['titel']}] ist durchlaufen. 'koordinat los \"...\"' startet den naechsten Ablauf."
    db.execute("INSERT OR REPLACE INTO leitfaden_stand VALUES(?,?,?)", (a["id"], i, time.time()))
    db.commit()
    return _schritt_text(a, i)


def plan(db, anliegen):
    """Fuer die KI (MCP): der ganze Ablauf auf einmal, als Plan zum Abarbeiten - mit Werkzeugen je Schritt."""
    a = _ablauf(anliegen.strip()) or finde(anliegen)
    if not a:
        return dict(gefunden=False, verfuegbar=[dict(id=x["id"], titel=x["titel"]) for x in ablaeufe()])
    return dict(gefunden=True, id=a["id"], titel=a["titel"], ziel=a.get("ziel", ""),
                schritte=[dict(nr=i + 1, titel=s["titel"], text=s["text"].strip(), werkzeug=s.get("werkzeug"),
                               projekte=s.get("projekte", []), befehl=s.get("befehl")) for i, s in enumerate(a["schritte"])])


def inhalt():
    z = ["Gefuehrte Ablaeufe (koordinat los \"<anliegen>\"):", ""]
    for a in ablaeufe():
        z.append(f"  {a['id']:<20} {a['titel']}")
        z.append(f"  {'':<20} {a.get('ziel', '')}")
    return "\n".join(z)
