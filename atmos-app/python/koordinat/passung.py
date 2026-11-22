"""PASSUNG - welches Modul passt zu welchem Problem. Aktivieren nur bei Eignung."""
import re
SCHWELLE = 0.35
def _woerter(t):
    return {w for w in re.findall(r"[a-z0-9]+", t.lower()) if len(w) > 2}
def passung(db, name, problemtyp):
    r = db.execute("SELECT beschreibung, stack FROM modul WHERE name=?", (name,)).fetchone()
    if not r:
        return 0.0
    p = _woerter(problemtyp)
    if not p:
        return 0.0
    text = _woerter((r[0] or "") + " " + name.replace("/", " ") + " " + (r[1] or ""))
    return round(len(p & text) / len(p), 3)
def kandidaten(db, problemtyp, vital):
    out = []
    for r in db.execute("SELECT name, score, lizenzklasse, sicherheit, schalter FROM modul"):
        if (vital.wert(r[0]) or 0) <= 0 or r[2] == "keine" or r[3] == "gesperrt":
            continue
        p = passung(db, r[0], problemtyp)
        if p < SCHWELLE:
            continue
        out.append(dict(name=r[0], passung=p, score=r[1], an=bool(r[4])))
    return sorted(out, key=lambda x: (-x["passung"], -x["score"]))
def aktiviere_fuer(db, vital, problemtyp, nur_bestes=True):
    from . import module
    k = kandidaten(db, problemtyp, vital)
    if not k:
        return False, f"Kein Modul passt auf '{problemtyp}'."
    ok, meldung = module.schalte(db, vital, k[0]["name"], True)
    if not ok:
        return False, meldung
    if nur_bestes:
        for x in k[1:]:
            if x["an"]:
                module.schalte(db, vital, x["name"], False)
    return True, f"{k[0]['name']} aktiv fuer '{problemtyp}' (Passung {k[0]['passung']})."
