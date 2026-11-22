"""ERKLAEREN - Lehrpfad in drei Stufen. Ohne bestandene Prueffrage keine naechste Stufe."""
import json, pathlib, re, time
STUFEN = {1: "Einstieg", 2: "Aufbau", 3: "Vertiefung"}
_DATEI = pathlib.Path(__file__).parent / "themen.json"
def themen():
    return json.loads(_DATEI.read_text())
def _norm(t):
    t = t.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        t = t.replace(a, b)
    return t
def finde(begriff):
    ws = [w for w in re.findall(r"[\w.\-]+", _norm(begriff)) if len(w) > 1]
    best, bp = None, 0
    for t in themen():
        namen = [_norm(x) for x in [t["id"], t["titel"]] + t["begriffe"]]
        p = sum(10 if w in namen else 4 if any(w in x for x in namen) else 0 for w in ws)
        if p > bp:
            best, bp = t, p
    return best if bp >= 4 else None
def stufe_stand(db, thema):
    r = db.execute("SELECT stufe, bestanden FROM lehr_stand WHERE thema=?", (thema,)).fetchone()
    return (r[0], r[1]) if r else (0, 0)
def _hoechste(t):
    return max(int(k) for k in t["stufen"])
def freigabe(db, thema):
    t = next((x for x in themen() if x["id"] == thema), None)
    if not t:
        return 0
    for v in t.get("voraussetzung", []):
        if stufe_stand(db, v)[1] < 1:
            return 0
    st, best = stufe_stand(db, thema)
    return 1 if st == 0 else st if not best else min(st + 1, _hoechste(t))
def erklaere(db, begriff, stufe=None):
    t = finde(begriff)
    if not t:
        db.execute("INSERT INTO guide_luecke VALUES(?,1,?) ON CONFLICT(begriff) DO UPDATE SET "
                   "anzahl=anzahl+1, zeit=excluded.zeit", (_norm(begriff)[:80], time.time()))
        db.commit()
        return f"Zu '{begriff}' fehlt ein Thema. Luecke notiert."
    s = min(stufe or freigabe(db, t["id"]), _hoechste(t))
    if s == 0:
        offen = [x["titel"] for x in themen() if x["id"] in t.get("voraussetzung", [])]
        return f"Vorher noetig: {', '.join(offen)}. Dann '{t['id']}' erneut aufrufen."
    block = t["stufen"][str(s)]
    db.execute("INSERT OR REPLACE INTO lehr_stand VALUES(?,?,?,?)", (t["id"], s, 0, time.time()))
    db.commit()
    z = [f"{t['titel']} - Stufe {s} ({STUFEN[s]})", "", "Bild: " + block["analogie"], "", "Schritte:"]
    z += [f" {i}. {x}" for i, x in enumerate(block["schritte"], 1)]
    z += ["", "Typische Fehler:"] + [f" - {x}" for x in block["fehler"]]
    z += ["", "Prueffrage: " + block["pruef"]]
    if s < _hoechste(t):
        z.append(f"\nAntwort mit 'pruefe {t['id']} <antwort>', dann Stufe {s + 1}.")
    return "\n".join(z)
def pruefe(db, thema, antwort):
    t = next((x for x in themen() if x["id"] == thema or _norm(x["titel"]) == _norm(thema)), None)
    if not t:
        return False, "Thema unbekannt."
    st, _ = stufe_stand(db, t["id"])
    if st == 0:
        return False, "Erst erklaeren lassen."
    block = t["stufen"][str(st)]
    ws = {w for w in re.findall(r"[a-z0-9]+", _norm(antwort)) if len(w) > 2}
    soll = {w for w in re.findall(r"[a-z0-9]+", _norm(" ".join(block["schritte"]) + " " + block["analogie"]))
            if len(w) > 3}
    if not soll:
        return True, "Angenommen."
    q = len(ws & soll) / len(soll)
    ok = q >= 0.06 or len(ws) >= 4
    db.execute("INSERT OR REPLACE INTO lehr_stand VALUES(?,?,?,?)", (t["id"], st, 1 if ok else 0, time.time()))
    db.commit()
    return ((True, f"Bestanden ({q * 100:.0f} Prozent Treffer). Stufe {min(st + 1, _hoechste(t))} frei.")
            if ok else (False, "Noch nicht. Nenne mindestens zwei der Schritte in eigenen Worten."))
def pfad(db, ziel):
    t = finde(ziel)
    if not t:
        return [x["id"] for x in themen() if not x.get("voraussetzung")][:5]
    order, seen = [], set()
    def geh(x):
        if x["id"] in seen:
            return
        seen.add(x["id"])
        for v in x.get("voraussetzung", []):
            y = next((z for z in themen() if z["id"] == v), None)
            if y:
                geh(y)
        order.append(x["id"])
    geh(t)
    return order
def inhalt():
    z = ["Lehrpfad (erklaere <begriff>):", ""]
    for t in themen():
        z.append(f" {t['id']:<20} {t['titel']:<38} vorher: {', '.join(t.get('voraussetzung', [])) or '-'}")
    return "\n".join(z)
