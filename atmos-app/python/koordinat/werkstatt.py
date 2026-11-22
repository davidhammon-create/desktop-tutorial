"""WERKSTATT - ganze Arbeitsgaenge fahren, mit Spur, Artefakten und gestuften Freigaben.
Freigaben haben eine Stufe: 0 harmlos, 1 teuer. --ja ueberspringt nur Stufe 0.
"""
import json, pathlib, time
from . import haltung, github, modelle, speicher, trace, verfassung
MAX_JE_LAUF = 40
def _ordner(lauf):
    p = verfassung.HEIM / "laeufe" / str(lauf)
    p.mkdir(parents=True, exist_ok=True)
    return p
def neu(db, plan):
    a = plan["ablauf"]
    c = db.execute("INSERT INTO lauf(ablauf,titel,ziel,schritt,stand,eingaben,zeit,quelle) "
                   "VALUES(?,?,?,?,?,?,?,?)",
                   (a["id"], a["titel"], a.get("ziel", ""), 0, "offen", "{}", time.time(), plan["quelle"]))
    db.commit()
    return c.lastrowid
def _lade(db, lauf):
    r = db.execute("SELECT id, ablauf, titel, ziel, schritt, stand, eingaben FROM lauf WHERE id=?",
                   (lauf,)).fetchone()
    if not r:
        raise LookupError("Lauf nicht gefunden.")
    return dict(id=r[0], ablauf=r[1], titel=r[2], ziel=r[3], schritt=r[4], stand=r[5],
                eingaben=json.loads(r[6]))
def _setze(db, lauf, **felder):
    for k, v in felder.items():
        db.execute(f"UPDATE lauf SET {k}=? WHERE id=?",
                   (json.dumps(v, ensure_ascii=False) if k == "eingaben" else v, lauf))
    db.commit()
def _schritte(ablauf_id):
    from . import planer
    a = next((x for x in planer.vorlagen() if x["id"] == ablauf_id), None)
    return a["schritte"] if a else []
def _ausfuehren(db, v, lauf, s, eingaben, trocken):
    art = s["art"]
    speicher.profil_zaehle(db, art)
    if trocken:
        return f"(trocken) {s['titel']}"
    if art == "erklaeren":
        from . import erklaeren
        return erklaeren.erklaere(db, s.get("thema") or "prompt")
    if art == "klaeren":
        return f"Ziel: {eingaben.get('ziel') or s.get('eingabe') or '(offen)'}"
    if art == "erkunden":
        from . import algorithmen
        return "\n".join(f"{t['score']:>3} {t['name']} ({t['lizenz'] or 'KEINE'})"
                         for t in github.suche(eingaben.get("ziel") or s["text"], 5,
                                               algorithmen.gewichte(db))) or "keine Treffer"
    if art == "schreiben":
        m = modelle.fuer_schritt("schreiben")
        return f"Entwurf von {m['name'] if m else 'lokal'}: {s['text']}"
    if art == "bauen":
        m = modelle.fuer_schritt("bauen")
        return f"gebaut mit {m['name'] if m else 'lokal'}: {s['titel']}"
    if art == "pruefen":
        return f"Pruefung gegen: {s['text']}"
    if art == "freigabe":
        return "Freigabe angefordert."
    raise ValueError(f"unbekannte Art: {art}")
def starte(db, v, plan, ja=False, trocken=False):
    if verfassung.stop_gesetzt():
        return None, "STOP ist gesetzt."
    if v.modus() == "sicher":
        return None, "Sicherer Modus. 'kern stand' pruefen."
    lauf = neu(db, plan)
    schritte = plan["ablauf"]["schritte"]
    if len(schritte) > MAX_JE_LAUF:
        return lauf, f"zu viele Schritte ({len(schritte)})"
    _setze(db, lauf, eingaben=dict(ziel=plan["ablauf"].get("ziel", "")))
    trace.schreibe(db, lauf, "plan", f"{plan['ablauf']['titel']} - {len(schritte)} Schritte",
                   haltung.beschreibe("fokus"))
    return _fahren(db, v, lauf, ja, trocken)
def _fahren(db, v, lauf, ja, trocken):
    while True:
        l = _lade(db, lauf)
        schritte = _schritte(l["ablauf"])
        if l["stand"] in ("fertig", "abgebrochen"):
            return lauf, f"Lauf {lauf} ist {l['stand']}."
        i = l["schritt"]
        if i >= len(schritte):
            _setze(db, lauf, stand="fertig")
            trace.schreibe(db, lauf, "ende", "fertig")
            return lauf, f"Lauf {lauf} fertig."
        s = schritte[i]
        m = modelle.fuer_schritt(s["art"])
        trace.schreibe(db, lauf, "schritt", f"{i + 1}/{len(schritte)} {s['titel']}",
                       s.get("erklaerung", ""), modell=(m["name"] if m else ""))
        try:
            ergebnis = _ausfuehren(db, v, lauf, s, l["eingaben"], trocken)
        except Exception as e:
            trace.schreibe(db, lauf, "fehler", f"{type(e).__name__}: {e}")
            _setze(db, lauf, stand="fehler")
            return lauf, f"Schritt {i + 1} gescheitert: {e}"
        if not trocken:
            (_ordner(lauf) / f"{i + 1:02d}_{s['art']}.txt").write_text(str(ergebnis))
        trace.schreibe(db, lauf, "ergebnis", str(ergebnis)[:300], modell=(m["name"] if m else ""))
        _setze(db, lauf, schritt=i + 1)
        if s["art"] == "freigabe" and not (ja and s.get("stufe", 1) == 0):
            _setze(db, lauf, stand="halt")
            trace.schreibe(db, lauf, "halt", f"wartet auf Freigabe nach Schritt {i + 1}",
                           haltung.beschreibe("entscheidungsstaerke"))
            return lauf, f"Lauf {lauf} haelt bei Schritt {i + 1}. 'koordinat weiter {lauf}'."
        if not ja:
            break
    return lauf, f"Lauf {lauf} bei Schritt {_lade(db, lauf)['schritt']}."
def weiter(db, v, lauf, ja=False, trocken=False):
    if _lade(db, lauf)["stand"] == "halt":
        _setze(db, lauf, stand="laeuft")
    return _fahren(db, v, lauf, ja, trocken)
def abbrechen(db, lauf):
    _lade(db, lauf)
    _setze(db, lauf, stand="abgebrochen")
    trace.schreibe(db, lauf, "ende", "abgebrochen durch Menschen")
    return f"Lauf {lauf} abgebrochen. Ergebnisse bleiben in {_ordner(lauf)}."
def laeufe(db):
    return [dict(id=r[0], titel=r[1], schritt=r[2], stand=r[3]) for r in db.execute(
        "SELECT id, titel, schritt, stand FROM lauf ORDER BY id DESC LIMIT 40")]
def stand(db, lauf):
    l = _lade(db, lauf)
    schritte = _schritte(l["ablauf"])
    z = [f"Lauf {l['id']}: {l['titel']} - {l['stand']} ({l['schritt']}/{len(schritte)})"]
    for i, s in enumerate(schritte):
        z.append(f" {'>' if i == l['schritt'] else '+' if i < l['schritt'] else ' '} "
                 f"{i + 1}. {s['titel']} [{s['art']}]")
    return "\n".join(z)
