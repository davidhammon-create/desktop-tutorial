"""LEITFADEN - gefuehrter Ablauf Schritt fuer Schritt, fuer Menschen und fuer KI."""
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
    ws = [w for w in re.findall(r"[a-z0-9+#]+", _norm(anliegen)) if len(w) > 2]
    if not ws:
        return None
    best, bp = None, 0
    for a in ablaeufe():
        heu, titel = _norm(" ".join(a["ausloeser"])), _norm(a["titel"])
        p = sum(4 * (w in heu.split()) + 2 * (w in heu) + 3 * (w in titel) for w in ws)
        if p > bp:
            best, bp = a, p
    return best if bp >= 4 else None
def _ablauf(kennung):
    return next((a for a in ablaeufe() if a["id"] == kennung), None)
def _text(a, i):
    s = a["schritte"][i]
    kopf = f"[{a['titel']}] Schritt {i + 1} von {len(a['schritte'])}: {s['titel']}"
    z = [kopf, "-" * len(kopf), s["text"].strip()]
    if s.get("tipp"):
        z.append("Tipp: " + s["tipp"])
    if s.get("werkzeug"):
        z.append("Werkzeug: " + s["werkzeug"])
    if s.get("befehl"):
        z.append("Befehl: " + s["befehl"])
    z.append("\n-> 'koordinat weiter-leitfaden'" if len(a["schritte"]) - i - 1 else "\n-> Letzter Schritt.")
    return "\n".join(z)
def los(db, anliegen):
    a = finde(anliegen)
    if not a:
        return ("Kein Ablauf dazu. Vorhanden: " + ", ".join(x["titel"] for x in ablaeufe())
                + f". Oder 'koordinat erklaere {anliegen}'.")
    db.execute("INSERT OR REPLACE INTO leitfaden_stand VALUES(?,?,?)", (a["id"], 0, time.time()))
    db.execute("INSERT OR REPLACE INTO einstellung VALUES('_leitfaden_aktiv', ?)", (a["id"],))
    db.commit()
    return _text(a, 0)
def weiter(db):
    r = db.execute("SELECT wert FROM einstellung WHERE name='_leitfaden_aktiv'").fetchone()
    if not r or not _ablauf(r[0]):
        return "Kein Ablauf laeuft. 'koordinat los \"<anliegen>\"'."
    a = _ablauf(r[0])
    st = db.execute("SELECT schritt FROM leitfaden_stand WHERE ablauf=?", (a["id"],)).fetchone()
    i = (st[0] if st else 0) + 1
    if i >= len(a["schritte"]):
        db.execute("DELETE FROM einstellung WHERE name='_leitfaden_aktiv'")
        db.commit()
        return f"[{a['titel']}] durch."
    db.execute("INSERT OR REPLACE INTO leitfaden_stand VALUES(?,?,?)", (a["id"], i, time.time()))
    db.commit()
    return _text(a, i)
def plan(db, anliegen):
    a = finde(anliegen)
    if not a:
        return dict(gefunden=False, verfuegbar=[dict(id=x["id"], titel=x["titel"]) for x in ablaeufe()])
    return dict(gefunden=True, id=a["id"], titel=a["titel"], ziel=a.get("ziel", ""),
                schritte=[dict(nr=i + 1, titel=s["titel"], text=s["text"].strip(),
                               werkzeug=s.get("werkzeug"), befehl=s.get("befehl"))
                          for i, s in enumerate(a["schritte"])])
def inhalt():
    return "Gefuehrte Ablaeufe:\n\n" + "\n".join(f" {a['id']:<20} {a['titel']}" for a in ablaeufe())
