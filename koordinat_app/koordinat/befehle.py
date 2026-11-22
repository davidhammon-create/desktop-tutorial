"""BEFEHLE - Nachschlagewerk aller wichtigen Befehle und Regler der KI-Werkzeuge (befehle.json).
Ein neuer Eintrag ist eine Zeile in befehle.json, ohne Programmierung."""
import json, pathlib, re

_DATEI = pathlib.Path(__file__).parent / "befehle.json"


def alle():
    return json.loads(_DATEI.read_text())


def werkzeuge():
    return list(dict.fromkeys(e["werkzeug"] for e in alle()))


def _norm(t):
    t = t.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        t = t.replace(a, b)
    return t


def suche(begriff="", werkzeug=None, n=0):
    """Volltextsuche ueber Werkzeug, Gruppe, Befehl und Erklaerung; alle Woerter muessen vorkommen."""
    woerter = [w for w in re.split(r"\s+", _norm(begriff)) if w]
    out = []
    for e in alle():
        if werkzeug and _norm(e["werkzeug"]) != _norm(werkzeug):
            continue
        text = _norm(" ".join(e.values()))
        if all(w in text for w in woerter):
            out.append(e)
    return out[:n] if n else out


def als_text(eintraege):
    if not eintraege:
        return "Nichts gefunden. 'koordinat befehle' zeigt alle Werkzeuge."
    z, w_alt = [], None
    for e in eintraege:
        if e["werkzeug"] != w_alt:
            z.append(f"\n== {e['werkzeug']}")
            w_alt = e["werkzeug"]
        z.append(f"  [{e['gruppe']}] {e['befehl']}\n      {e['was']}")
    return "\n".join(z).lstrip()


def inhalt():
    zaehl = {}
    for e in alle():
        zaehl[e["werkzeug"]] = zaehl.get(e["werkzeug"], 0) + 1
    return ("Befehle und Regler je Werkzeug  (koordinat befehle <werkzeug|suchwort>)\n"
            + "\n".join(f"  {w:<18} {n:>3} Eintraege" for w, n in zaehl.items()))
