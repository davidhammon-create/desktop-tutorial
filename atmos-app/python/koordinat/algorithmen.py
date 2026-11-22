"""Die lernenden Algorithmen: Repo-Bewertung und Rangfolge der Bausteine."""
import pathlib, re
from . import evolution, github
def _score_einheiten(db, faelle):
    gruppen = {}
    for f in faelle:
        g = gruppen.setdefault(f["gruppe"], dict(schluessel=f["gruppe"], min_id=f["id"], daten=([], [])))
        g["daten"][0 if f["label"] else 1].append(f["f"])
    return [g for g in gruppen.values() if g["daten"][0] and g["daten"][1]]
def _score_guete(p, daten):
    out = []
    for gut, schlecht in daten:
        pg, ps = [github.punkte(f, p) for f in gut], [github.punkte(f, p) for f in schlecht]
        out.append(sum(1.0 if a > b else 0.5 if a == b else 0.0 for a in pg for b in ps) / (len(pg) * len(ps)))
    return out
evolution.registriere(evolution.Algorithmus(
    "repo_score", "Gewichte der Repo-Bewertung",
    dict(passung=(5, 50, 20), beliebt=(5, 50, 30), aktiv=(5, 40, 20), lizenz=(5, 40, 15),
         echt=(0, 20, 5), handlich=(0, 30, 10)), _score_einheiten, _score_guete))
def gewichte(db):
    return evolution.params(db, "repo_score")
RANG = ("alt", "exakt", "name", "pfad", "zeile", "test", "privat", "tiefe")
def woerter(frage):
    return [x for x in re.findall(r"\w+", frage.lower()) if len(x) > 2]
def _teile(name):
    return {t.lower() for t in re.findall(r"[A-Z]+(?![a-z])|[A-Z]?[a-z]+|\d+", name)}
def merkmale(ws, sym):
    d, _, nm, zl = sym
    dl, nl, zll, n = d.lower(), nm.lower(), zl.lower(), max(len(ws), 1)
    alles, teile = dl + " " + nl + " " + zll, _teile(nm)
    return (sum(w in alles for w in ws) / n, sum(w in teile for w in ws) / n, sum(w in nl for w in ws) / n,
            sum(w in dl for w in ws) / n, sum(w in zll for w in ws) / n,
            1.0 if re.search(r"(^|[/_.\-])(tests?|spec|examples?|docs?)([/_.\-]|$)", dl) else 0.0,
            1.0 if nm.startswith("_") else 0.0, min(dl.count("/"), 5) / 5)
def _punkt(p, m):
    return sum(p[k] * x for k, x in zip(RANG, m))
def ordne(sym, frage, p):
    ws = woerter(frage)
    if not ws:
        return sym
    return [s for _, _, s in sorted(((-_punkt(p, merkmale(ws, s)), i, s) for i, s in enumerate(sym)),
                                    key=lambda t: t[:2])]
def _rang_einheiten(db, faelle):
    from . import module
    cache, out = {}, []
    for f in faelle:
        if f["modul"] not in cache:
            r = db.execute("SELECT pfad FROM modul WHERE name=?", (f["modul"],)).fetchone()
            cache[f["modul"]] = module.symbole(pathlib.Path(r[0])) if r and pathlib.Path(r[0]).exists() else []
        sym, ws = cache[f["modul"]], woerter(f["frage"])
        ziele = [i for i, s in enumerate(sym) if s[2] == f["symbol"]]
        if ziele and ws:
            out.append(dict(schluessel=f["gruppe"], min_id=f["id"],
                            daten=([merkmale(ws, s) for s in sym], ziele)))
    return out
def _rang_guete(p, daten):
    out = []
    for ms, ziele in daten:
        pkt = [_punkt(p, m) for m in ms]
        out.append(max(1.0 / (1 + sum(1 for j, x in enumerate(pkt) if x > pkt[t])) for t in ziele))
    return out
evolution.registriere(evolution.Algorithmus(
    "kontext_rang", "Rangfolge der Bausteine im Kontextpaket",
    dict(alt=(0, 3, 1), exakt=(0, 3, 0), name=(0, 3, 0), pfad=(0, 3, 0), zeile=(0, 3, 0),
         test=(-3, 0, 0), privat=(-2, 0, 0), tiefe=(-1, 0, 0)), _rang_einheiten, _rang_guete))
