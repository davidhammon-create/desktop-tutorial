"""GITHUB - suchen, Metadaten, bewerten, Lizenz einordnen."""
import datetime, json, math, os, re, urllib.parse, urllib.request
API = "https://api.github.com"
FREI = {"MIT", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Apache-2.0", "Unlicense", "0BSD", "Zlib",
        "BSL-1.0", "CC0-1.0"}
BEDINGT = {"MPL-2.0", "LGPL-2.1", "LGPL-3.0", "EPL-2.0"}
COPYLEFT = {"GPL-2.0", "GPL-3.0", "AGPL-3.0"}
def _get(pfad):
    req = urllib.request.Request(API + pfad, headers={"Accept": "application/vnd.github+json",
                                                      "User-Agent": "koordinat/2.1"})
    if os.environ.get("GITHUB_TOKEN"):
        req.add_header("Authorization", "Bearer " + os.environ["GITHUB_TOKEN"])
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())
def lizenzklasse(spdx):
    if not spdx:
        return "keine"
    if spdx in FREI:
        return "frei"
    if spdx in BEDINGT:
        return "bedingt"
    if spdx in COPYLEFT:
        return "copyleft"
    return "unklar"
def _kurz(r):
    spdx = (r.get("license") or {}).get("spdx_id")
    if spdx == "NOASSERTION":
        spdx = "ANDERE"
    return dict(name=r["full_name"], beschreibung=(r.get("description") or "")[:200],
                sterne=r["stargazers_count"], forks=r["forks_count"],
                offene_issues=r["open_issues_count"], sprache=r.get("language") or "",
                themen=r.get("topics", []), lizenz=spdx or "",
                lizenzklasse=lizenzklasse(spdx if spdx != "ANDERE" else "x"),
                letzter_push=r["pushed_at"][:10], archiviert=r.get("archived", False),
                groesse_kb=r.get("size", 0), url=r["html_url"])
def meta(name):
    try:
        return _kurz(_get("/repos/" + name))
    except Exception:
        items = _get("/search/repositories?q=repo:" + urllib.parse.quote(name) + "+fork:true").get("items", [])
        if not items:
            raise LookupError(f"Repo nicht gefunden: {name}")
        return _kurz(items[0])
GEWICHTE = dict(passung=20.0, beliebt=30.0, aktiv=20.0, lizenz=15.0, echt=5.0, handlich=10.0)
def merkmale(m, begriff=""):
    tage = (datetime.date.today() - datetime.date.fromisoformat(m["letzter_push"])).days
    aktiv = 1.0 if tage < 30 else 0.7 if tage < 180 else 0.4 if tage < 365 else 0.1
    if m["archiviert"]:
        aktiv = 0.0
    liz = {"frei": 1.0, "bedingt": 0.8, "copyleft": 0.4, "unklar": 0.3, "keine": 0.0}[m["lizenzklasse"]]
    verh = (m["forks"] + m["offene_issues"]) / max(m["sterne"], 1)
    echt = 0.5 if m["sterne"] < 200 else 1.0 if verh > 0.03 else 0.5 if verh > 0.01 else 0.0
    handlich = 1.0 if m["groesse_kb"] < 50_000 else 0.6 if m["groesse_kb"] < 500_000 else 0.3
    passung = 0.6
    if begriff:
        woerter = [w for w in re.findall(r"\w+", begriff.lower()) if len(w) > 2]
        text = " ".join([m["name"], m["beschreibung"], " ".join(m["themen"])]).lower()
        passung = sum(w in text for w in woerter) / max(len(woerter), 1)
    return dict(passung=passung, beliebt=min(1.0, math.log10(m["sterne"] + 1) / 5), aktiv=aktiv,
                lizenz=liz, echt=echt, handlich=handlich, unbewaehrt=m["sterne"] < 50)
def punkte(f, gewichte=None):
    g = gewichte or GEWICHTE
    p = 100 * sum(g[k] * f[k] for k in GEWICHTE) / (sum(g[k] for k in GEWICHTE) or 1)
    return min(p, 55.0) if f["unbewaehrt"] else p
def score(m, begriff="", gewichte=None):
    return round(punkte(merkmale(m, begriff), gewichte))
def suche(begriff, n=8, gewichte=None):
    woerter = [w for w in re.findall(r"\w+", begriff) if len(w) > 2]
    anfragen = [begriff] + ([" ".join(woerter[:2])] if len(woerter) > 2 else [])
    treffer = {}
    for q in anfragen:
        d = _get(f"/search/repositories?q={urllib.parse.quote(q)}&sort=stars&order=desc&per_page=30")
        for r in d.get("items", []):
            treffer.setdefault(r["full_name"], _kurz(r))
    for t in treffer.values():
        t["score"] = score(t, begriff, gewichte)
    return sorted(treffer.values(), key=lambda t: -t["score"])[:n]
def thema(topic, n=15, min_sterne=300):
    q = urllib.parse.quote(f"topic:{topic} stars:>={min_sterne} archived:false")
    return [_kurz(r) for r in _get(f"/search/repositories?q={q}&sort=stars&order=desc&per_page={n}").get("items", [])]
