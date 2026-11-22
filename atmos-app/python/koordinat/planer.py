"""PLANER - freier Auftrag wird zum Ablauf. Erst Vorlagen, dann Bausteine."""
import json, pathlib, re
_B = pathlib.Path(__file__).parent / "ablaeufe.json"
FUELL = {"und", "oder", "fuer", "mit", "aus", "ein", "eine", "einen", "der", "die", "das",
         "von", "zu", "im", "in", "am", "bitte", "mal", "mir", "ich", "will", "brauche",
         "baue", "bau", "mach", "erstell", "erstellen", "the"}
BAUSTEINE = [
    ("klaeren", "Ziel klaeren", "Was genau soll am Ende dastehen, in einem Satz.",
     "Ohne Ziel kein Abbruchkriterium.", 0),
    ("erkunden", "Umfeld erkunden", "Welche Bausteine gibt es, welche Lizenzen.",
     "Erst sehen, was da ist.", 1),
    ("entwerfen", "Entwurf", "Grober Aufbau, drei Varianten, eine gewaehlt.",
     "Der billigste Moment fuer Korrekturen.", 1),
    ("bauen", "Bauen", "Kleinster lauffaehiger Stand.", "Erst laufen, dann schoen.", 2),
    ("pruefen", "Pruefen", "Gegen das Ziel aus Schritt 1.", "Wer baut, prueft nicht.", 1),
    ("freigabe", "Abgeben", "Ergebnis vorlegen.", "Ohne Freigabe kein Abschluss.", 1),
]
def vorlagen():
    return json.loads(_B.read_text())
def _ws(t):
    return [w for w in re.findall(r"[a-z0-9äöüß+#]+", t.lower()) if w not in FUELL and len(w) > 2]
def treffer(auftrag):
    ws = _ws(auftrag)
    if not ws:
        return None, 0
    best, bp = None, 0
    for v in vorlagen():
        heu = " ".join(v["ausloeser"] + [v["titel"]]).lower()
        p = sum(3 * (w in heu.split()) + 1 * (w in heu) for w in ws)
        if p > bp:
            best, bp = v, p
    return (best, bp) if bp >= 3 else (None, bp)
def baue(auftrag):
    return dict(id="frei", titel=f"Freier Auftrag: {auftrag[:60]}", ziel=auftrag, ausloeser=[],
                schritte=[dict(art=a, titel=t, text=x, erklaerung=e, stufe=s,
                               eingabe=auftrag if a in ("klaeren", "erkunden", "entwerfen") else "")
                          for a, t, x, e, s in BAUSTEINE])
def plan(auftrag):
    v, p = treffer(auftrag)
    return (dict(quelle=f"vorlage:{v['id']}", passung=p, ablauf=v) if v
            else dict(quelle="bausteine", passung=0, ablauf=baue(auftrag)))
