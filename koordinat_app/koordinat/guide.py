"""GUIDE - das eingebaute Nachschlagewerk. Inhalte liegen in guide.json (ein Eintrag je Begriff) und koennen
ohne Programmierung erweitert werden. Begriffe, die jemand sucht und die fehlen, werden als Luecke gezaehlt:
das ist der 'Hunger' des Guides und die Arbeitsliste fuer neue Eintraege."""
import json, pathlib, re, time

STUFE = {1: "Einstieg", 2: "Aufbau", 3: "Vertiefung"}


def eintraege():
    return json.loads((pathlib.Path(__file__).parent / "guide.json").read_text())


def _norm(t):
    t = t.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        t = t.replace(a, b)
    return t


def suche(frage, n=5):
    ws = [w for w in re.findall(r"[\w.\-]+", _norm(frage)) if len(w) > 1]
    out = []
    for e in eintraege():
        namen = [_norm(x) for x in [e["id"], e["titel"]] + e["begriffe"]]
        text = _norm(e["kurz"] + " " + e["text"])
        p = sum(10 * any(w == x or w in x.split() for x in namen) + 4 * any(w in x for x in namen) + (w in text) for w in ws)
        if p >= 4:
            out.append((p, e))
    return [e for _, e in sorted(out, key=lambda t: -t[0])[:n]]


def zeige(e):
    alle = {x["id"]: x["titel"] for x in eintraege()}
    siehe = ", ".join(alle.get(s, s) for s in e["siehe"])
    return f"{e['titel']}   [{STUFE[e['stufe']]}]\n{e['kurz']}\n\n{e['text']}" + (f"\n\nSiehe auch: {siehe}" if siehe else "")


def frage(db, begriff):
    """Antwort als Text. Fehlt der Begriff, wird die Luecke gemerkt."""
    if not begriff.strip():
        return inhalt()
    t = suche(begriff)
    if not t:
        db.execute("INSERT INTO guide_luecke VALUES(?,1,?) ON CONFLICT(begriff) DO UPDATE SET anzahl=anzahl+1, zeit=excluded.zeit",
                   (_norm(begriff.strip())[:80], time.time()))
        db.commit()
        return f"Zu '{begriff}' gibt es noch keinen Eintrag. Die Luecke ist notiert (koordinat guide-luecken)."
    return zeige(t[0]) + ("\n\nWeitere Treffer: " + ", ".join(e["titel"] for e in t[1:]) if len(t) > 1 else "")


def inhalt():
    z = []
    for s, name in STUFE.items():
        z.append(f"{name}:")
        z += [f"  {e['id']:<18} {e['kurz']}" for e in eintraege() if e["stufe"] == s]
    return "\n".join(z)


def luecken(db):
    return [dict(begriff=r[0], gefragt=r[1]) for r in db.execute("SELECT begriff, anzahl FROM guide_luecke ORDER BY anzahl DESC LIMIT 50")]
