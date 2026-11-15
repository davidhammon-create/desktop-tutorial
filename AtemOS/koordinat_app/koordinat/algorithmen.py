"""Die Algorithmen der App, die sich selbst nachstellen duerfen (siehe evolution.py).

  repo_score    Wie stark zaehlen Beliebtheit, Passung, Aktivitaet, Lizenz ... bei der Bewertung eines Repos?
                Lernt aus: angenommenen und abgelehnten Vorschlaegen, 'geloest' und 'fehler_verborgen'.
  kontext_rang  Welche Bausteine eines Repos stehen zu einer Frage oben im Kontextpaket?
                Lernt aus: welchen Baustein die KI nach einer Frage tatsaechlich per 'auszug' geholt hat.

Ein neuer Algorithmus braucht drei Dinge: einen Parameterraum mit Grenzen, eine Funktion, die aus rohen
Faellen bewertbare Einheiten macht, und eine Guetefunktion. Die Standardwerte sind immer das von Hand
geschriebene Verhalten - ohne Faelle aendert sich also nichts.
"""
import pathlib, re
from . import evolution, github

# ------------------------------------------------------------------ repo_score
def _score_einheiten(db, faelle):
    gruppen = {}
    for f in faelle:
        g = gruppen.setdefault(f["gruppe"], dict(schluessel=f["gruppe"], min_id=f["id"], daten=([], [])))
        g["daten"][0 if f["label"] else 1].append(f["f"])
    return [g for g in gruppen.values() if g["daten"][0] and g["daten"][1]]     # braucht gut UND schlecht


def _score_guete(p, daten):
    """Je Bedarf: Anteil der Paare (gutes Repo, schlechtes Repo), die der Score richtig herum ordnet."""
    out = []
    for gut, schlecht in daten:
        pg, ps = [github.punkte(f, p) for f in gut], [github.punkte(f, p) for f in schlecht]
        out.append(sum(1.0 if a > b else 0.5 if a == b else 0.0 for a in pg for b in ps) / (len(pg) * len(ps)))
    return out


evolution.registriere(evolution.Algorithmus(
    "repo_score", "Gewichte der Repo-Bewertung",
    # Lizenz und Aktivitaet haben eine Untergrenze: die Evolution kann sie nicht wegoptimieren.
    dict(passung=(5, 50, 20), beliebt=(5, 50, 30), aktiv=(5, 40, 20), lizenz=(5, 40, 15), echt=(0, 20, 5), handlich=(0, 30, 10)),
    _score_einheiten, _score_guete))


def gewichte(db):
    return evolution.params(db, "repo_score")


# ------------------------------------------------------------------ kontext_rang
RANG = ("alt", "exakt", "name", "pfad", "zeile", "test", "privat", "tiefe")


def woerter(frage):
    return [x for x in re.findall(r"\w+", frage.lower()) if len(x) > 2]


def _teile(name):
    return {t.lower() for t in re.findall(r"[A-Z]+(?![a-z])|[A-Z]?[a-z]+|\d+", name)}


def merkmale(ws, sym):
    """sym = (datei, zeile, name, zeilentext). 'alt' ist das urspruengliche Mass von v0.2."""
    d, _, nm, zl = sym
    dl, nl, zll, n = d.lower(), nm.lower(), zl.lower(), max(len(ws), 1)
    alles, teile = dl + " " + nl + " " + zll, _teile(nm)
    return (sum(w in alles for w in ws) / n, sum(w in teile for w in ws) / n, sum(w in nl for w in ws) / n,
            sum(w in dl for w in ws) / n, sum(w in zll for w in ws) / n,
            1.0 if re.search(r"(^|[/_.\-])(tests?|spec|examples?|docs?|bench)([/_.\-]|$)", dl) else 0.0,
            1.0 if nm.startswith("_") else 0.0, min(dl.count("/"), 5) / 5)


def _punkt(p, m):
    return sum(p[k] * x for k, x in zip(RANG, m))


def ordne(sym, frage, p):
    """Sortiert Bausteine nach Naehe zur Frage (stabil: Gleichstand behaelt die Dateireihenfolge)."""
    ws = woerter(frage)
    if not ws:
        return sym
    return [s for _, _, s in sorted(((-_punkt(p, merkmale(ws, s)), i, s) for i, s in enumerate(sym)), key=lambda t: t[:2])]


def _rang_einheiten(db, faelle):
    from . import module                                    # spaet, weil module seinerseits ordne() nutzt
    cache, out = {}, []
    for f in faelle:
        if f["modul"] not in cache:
            r = db.execute("SELECT pfad FROM modul WHERE name=?", (f["modul"],)).fetchone()
            cache[f["modul"]] = module.symbole(pathlib.Path(r[0])) if r and pathlib.Path(r[0]).exists() else []
        sym, ws = cache[f["modul"]], woerter(f["frage"])
        ziele = [i for i, s in enumerate(sym) if s[2] == f["symbol"] and (not f.get("datei") or s[0] == f["datei"])]
        if ziele and ws:
            out.append(dict(schluessel=f["gruppe"], min_id=f["id"], daten=([merkmale(ws, s) for s in sym], ziele)))
    return out


def _rang_guete(p, daten):
    """Kehrwert des Rangs, auf dem der tatsaechlich gebrauchte Baustein steht (1 = ganz oben)."""
    out = []
    for ms, ziele in daten:
        pkt = [_punkt(p, m) for m in ms]
        out.append(max(1.0 / (1 + sum(1 for j, x in enumerate(pkt) if x > pkt[t] or (x == pkt[t] and j < t))) for t in ziele))
    return out


evolution.registriere(evolution.Algorithmus(
    "kontext_rang", "Rangfolge der Bausteine im Kontextpaket",
    dict(alt=(0, 3, 1), exakt=(0, 3, 0), name=(0, 3, 0), pfad=(0, 3, 0), zeile=(0, 3, 0),
         test=(-3, 0, 0), privat=(-2, 0, 0), tiefe=(-1, 0, 0)),
    _rang_einheiten, _rang_guete))
