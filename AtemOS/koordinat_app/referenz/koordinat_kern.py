#!/usr/bin/env python3
"""
KOORDINAT-KERN v0.1  -  lauffaehiger Referenzkern (nur Python-Standardbibliothek)

Zeigt in einem Stueck, messbar:
  1. Kaskade:        Cache -> Kristall -> Router (kleines/grosses Modell)
  2. Kristallisierung: aus geloggten Beispielen wird per Programmsynthese (ohne KI)
                     eine feste Formel, die nach Holdout-Test und Schattenbetrieb aktiv wird
  3. Router:         Thompson Sampling waehlt je Problemtyp das Modell mit bestem Nutzen
  4. Triage:         Ablation misst den Beitrag jedes Bausteins
  5. Quanten-Teil:   echte Grover-Simulation (zeigt, warum Simulation nichts spart)
                     und quanten-inspirierte Optimierung (Parallel Tempering) auf Max-Cut

WICHTIG: Die "Modelle" sind hier SIMULIERT (verborgene Formel + Fehlerquote + Preis),
damit der Kern ohne API-Schluessel laeuft. Echte Modelle werden in Kern.modell()
eingehaengt (siehe Kommentar dort). Die Mechanik drumherum ist echt.

Start:  python3 koordinat_kern.py
"""
import json, math, random, time

# ----------------------------------------------------------------------------
# 0) Die Welt: Problemtypen mit verborgener Wahrheit (nur zur Simulation/Auswertung)
# ----------------------------------------------------------------------------
_TAB = [1.13, 0.87, 1.42, 0.65, 1.08, 0.93, 1.27]          # nicht als Formel ausdrueckbar
INTENTS = {
    "prozent": (2, lambda a, b: a * b / 100),
    "brutto":  (2, lambda a, b: a * (1 + b / 100)),
    "rabatt":  (2, lambda a, b: a * (1 - b / 100)),
    "zins":    (3, lambda k, p, t: k * p * t / 100),
    "tarif":   (2, lambda a, b: a * _TAB[int(b) % 7]),      # bleibt Modell-Arbeit
}
P_KLEIN = {"prozent": 0.97, "brutto": 0.97, "rabatt": 0.60, "zins": 0.60, "tarif": 0.55}
P_GROSS = 0.99
PREIS = {"klein": 0.05, "gross": 1.00}                       # Cent pro Aufruf
FEHLERWERT = 5.0                                             # was ein Fehler "kostet" (Cent)


def wahrheit(intent, params):
    return round(INTENTS[intent][1](*params), 2)


def gleich(a, b):
    return abs(a - b) < 0.006


def anfragen_strom(n, seed):
    rng = random.Random(seed)
    betraege = [25 * i for i in range(1, 41)]
    saetze = [5, 7, 10, 15, 19, 20, 25, 50]
    out = []
    for _ in range(n):
        it = rng.choice(list(INTENTS))
        if it == "zins":
            p = (rng.choice(betraege[::2]) * 10, rng.choice([1, 2, 3, 4, 5]), rng.choice([1, 2, 3, 5, 10]))
        elif it == "tarif":
            p = (rng.choice(betraege), rng.randrange(14))
        else:
            p = (rng.choice(betraege), rng.choice(saetze))
        out.append((it, tuple(float(x) for x in p)))
    return out


# ----------------------------------------------------------------------------
# 1) Programmsynthese OHNE KI: kleinste Formel finden, die die Beispiele erklaert
#    (Bottom-up-Aufzaehlung mit Beobachtungs-Aequivalenz; kleinste zuerst = Ockham)
# ----------------------------------------------------------------------------
def synthese(beispiele, arity, max_blaetter=4, toleranz=0.85):
    X = [e[0] for e in beispiele]
    Y = [e[1] for e in beispiele]
    n = len(X)

    def passt(v):
        return sum(gleich(round(a, 2), y) for a, y in zip(v, Y)) / n >= toleranz

    terme = [(f"x{i}", tuple(x[i] for x in X)) for i in range(arity)]
    terme += [("1", (1.0,) * n), ("100", (100.0,) * n)]
    for s, v in terme:
        if passt(v):
            return s
    ebenen = {1: terme}
    gesehen = {t[1] for t in terme}
    for groesse in range(2, max_blaetter + 1):
        neu = []
        for links in range(1, groesse):
            for sa, va in ebenen[links]:
                for sb, vb in ebenen[groesse - links]:
                    for op in "+-*/":
                        if op in "+*" and sa > sb:
                            continue
                        try:
                            if op == "+":   v = tuple(a + b for a, b in zip(va, vb))
                            elif op == "-": v = tuple(a - b for a, b in zip(va, vb))
                            elif op == "*": v = tuple(a * b for a, b in zip(va, vb))
                            else:           v = tuple(a / b for a, b in zip(va, vb))
                        except ZeroDivisionError:
                            continue
                        key = tuple(round(z, 6) for z in v)
                        if key in gesehen:
                            continue
                        gesehen.add(key)
                        s = f"({sa}{op}{sb})"
                        if passt(v):
                            return s
                        neu.append((s, v))
        ebenen[groesse] = neu
    return None


def als_funktion(formel, arity):
    args = ",".join(f"x{i}" for i in range(arity))
    return eval(f"lambda {args}: round({formel}, 2)", {"__builtins__": {}, "round": round})


# ----------------------------------------------------------------------------
# 2) Der Kern: Kaskade + Router + Kristallisierung
# ----------------------------------------------------------------------------
class Kern:
    def __init__(self, cache=True, kristall=True, router=True, seed=1):
        self.an = dict(cache=cache, kristall=kristall, router=router)
        self.rng = random.Random(seed)
        self.kosten = 0.0
        self.cache, self.wartend = {}, {}
        self.beta = {it: {m: [1.0, 1.0] for m in PREIS} for it in INTENTS}
        self.beispiele = {it: [] for it in INTENTS}
        self.naechster_versuch = {it: 30 for it in INTENTS}
        self.pause = {it: 30 for it in INTENTS}
        self.schatten, self.aktiv, self.formeln, self.strikes = {}, {}, {}, {}
        self.ereignisse = []

    # --- Modellaufruf. Fuer echte Modelle hier ersetzen, z. B.:
    #     antwort = anthropic_client.messages.create(model=..., messages=[...])
    #     self.kosten += tokens * preis ; return parse(antwort)
    def modell(self, name, intent, params):
        self.kosten += PREIS[name]
        w = wahrheit(intent, params)
        p = P_GROSS if name == "gross" else P_KLEIN[intent]
        if self.rng.random() < p:
            return w
        return round(w * self.rng.choice([0.5, 0.9, 1.1, 1.19, 2.0]), 2)

    def waehle_modell(self, intent):
        if not self.an["router"]:
            return "gross"
        best, best_u = None, -1e9
        for m, (a, b) in self.beta[intent].items():
            u = self.rng.betavariate(a, b) * FEHLERWERT - PREIS[m]   # Thompson Sampling
            if u > best_u:
                best, best_u = m, u
        return best

    def anfrage(self, intent, params, t=0):
        fp = (intent, params)
        # Stufe 0: exakter Cache
        if self.an["cache"] and fp in self.cache:
            return self.cache[fp], 0
        # Stufe 1: aktiver Kristall (+ 2 % Stichprobe gegen grosses Modell)
        if self.an["kristall"] and intent in self.aktiv:
            ans = self.aktiv[intent](*params)
            if self.rng.random() < 0.02:
                if not gleich(ans, self.modell("gross", intent, params)):
                    self.strikes[intent] = self.strikes.get(intent, 0) + 1
                    if self.strikes[intent] >= 3:
                        del self.aktiv[intent]
                        self.ereignisse.append((t, intent, "DEAKTIVIERT"))
            return ans, 1
        # Stufe 2: Modell laut Router
        m = self.waehle_modell(intent)
        ans = self.modell(m, intent, params)
        if self.rng.random() < 0.25:                                  # Pruefer (Goldfaelle)
            ok = gleich(ans, wahrheit(intent, params))
            self.beta[intent][m][0 if ok else 1] += 1
        # Cache erst nach zwei identischen Antworten (K1-Regel)
        if self.an["cache"]:
            if fp in self.wartend and gleich(self.wartend[fp], ans):
                self.cache[fp] = ans
            else:
                self.wartend[fp] = ans
        if self.an["kristall"]:
            self._kristallisiere(intent, params, ans, t)
        return ans, 2

    def _kristallisiere(self, intent, params, ans, t):
        ex = self.beispiele[intent]
        ex.append((params, ans))
        if intent in self.schatten:                                   # Schattenbetrieb
            f, st = self.schatten[intent]
            st[0] += gleich(f(*params), ans)
            st[1] += 1
            if st[1] >= 40:
                del self.schatten[intent]
                if st[0] / st[1] >= 0.85:
                    self.aktiv[intent] = f
                    self.ereignisse.append((t, intent, "AKTIV " + self.formeln[intent]))
                else:
                    self.ereignisse.append((t, intent, "Schatten nicht bestanden"))
            return
        if len(ex) >= self.naechster_versuch[intent]:
            letzte = ex[-30:]
            arity = INTENTS[intent][0]
            formel = synthese(letzte[:20], arity)
            ok = False
            if formel:
                f = als_funktion(formel, arity)
                ok = sum(gleich(f(*p), y) for p, y in letzte[20:]) / 10 >= 0.85   # Holdout
            if ok:
                self.schatten[intent] = (f, [0, 0])
                self.formeln[intent] = formel
                self.ereignisse.append((t, intent, "Kandidat " + formel))
            else:                                                     # Reha mit wachsender Pause
                self.pause[intent] *= 2
            self.naechster_versuch[intent] = len(ex) + self.pause[intent]


def lauf(strom, **flags):
    k = Kern(**flags)
    stufen, fehler, bloecke, letzte = [0, 0, 0], 0, [], 0.0
    for t, (it, p) in enumerate(strom, 1):
        ans, st = k.anfrage(it, p, t)
        stufen[st] += 1
        fehler += not gleich(ans, wahrheit(it, p))
        if t % 500 == 0:
            bloecke.append(round(k.kosten - letzte, 2))
            letzte = k.kosten
    n = len(strom)
    return dict(kosten=round(k.kosten, 2), fehlerquote=round(100 * fehler / n, 2),
                anteil_cache=round(100 * stufen[0] / n, 1), anteil_kristall=round(100 * stufen[1] / n, 1),
                anteil_modell=round(100 * stufen[2] / n, 1), bloecke=bloecke,
                ereignisse=k.ereignisse, formeln=k.formeln,
                router={it: {m: [round(x, 0) for x in ab] for m, ab in d.items()} for it, d in k.beta.items()})


# ----------------------------------------------------------------------------
# 3) Quanten, ehrlich: echte Grover-Simulation auf dem Zustandsvektor
# ----------------------------------------------------------------------------
def grover(n_qubits=10, ziel=777):
    N = 2 ** n_qubits
    a = [1 / math.sqrt(N)] * N
    runden = int(math.pi / 4 * math.sqrt(N))
    ops = 0
    for _ in range(runden):
        a[ziel] = -a[ziel]                      # Orakel
        m = sum(a) / N
        a = [2 * m - x for x in a]              # Diffusion (Spiegelung am Mittelwert)
        ops += 2 * N
    return dict(qubits=n_qubits, zustaende=N, quanten_abfragen=runden,
                trefferwahrscheinlichkeit=round(a[ziel] ** 2, 4),
                klassische_rechenschritte_der_simulation=ops, klassische_suche_mittel=N // 2)


def speicherbedarf():
    return {n: 16 * 2 ** n for n in (10, 20, 30, 40, 50, 60)}   # Bytes (komplex128)


# ----------------------------------------------------------------------------
# 4) Quanten-INSPIRIERT: Parallel Tempering vs. Annealing vs. gierige Suche (Max-Cut)
# ----------------------------------------------------------------------------
def graph(n, p, rng):
    nb = [[] for _ in range(n)]
    m = 0
    for i in range(n):
        for j in range(i + 1, n):
            if rng.random() < p:
                nb[i].append(j); nb[j].append(i); m += 1
    return nb, m


def cut(nb, s):
    return sum(1 for i in range(len(nb)) for j in nb[i] if j > i and s[i] != s[j])


def gewinn(nb, s, i):        # Aenderung des Schnitts, wenn Knoten i die Seite wechselt
    gleichseitig = sum(1 for j in nb[i] if s[j] == s[i])
    return 2 * gleichseitig - len(nb[i])


def gierig(nb, budget, rng):
    n, best, used = len(nb), 0, 0
    while used < budget:
        s = [rng.random() < 0.5 for _ in range(n)]
        c = cut(nb, s)
        still = 0
        while still < 3 * n and used < budget:
            i = rng.randrange(n); used += 1
            g = gewinn(nb, s, i)
            if g > 0:
                s[i] = not s[i]; c += g; still = 0
            else:
                still += 1
        best = max(best, c)
    return best


def annealing(nb, budget, rng, t0=2.0, t1=0.05):
    n = len(nb)
    s = [rng.random() < 0.5 for _ in range(n)]
    c = best = cut(nb, s)
    for k in range(budget):
        T = t0 * (t1 / t0) ** (k / budget)
        i = rng.randrange(n)
        g = gewinn(nb, s, i)
        if g >= 0 or rng.random() < math.exp(g / T):
            s[i] = not s[i]; c += g; best = max(best, c)
    return best


def parallel_tempering(nb, budget, rng, repliken=8, t_min=0.1, t_max=2.5):
    n = len(nb)
    Ts = [t_min * (t_max / t_min) ** (r / (repliken - 1)) for r in range(repliken)]
    S = [[rng.random() < 0.5 for _ in range(n)] for _ in range(repliken)]
    C = [cut(nb, s) for s in S]
    best, used = max(C), 0
    while used < budget:
        for r in range(repliken):
            for _ in range(n):
                i = rng.randrange(n); used += 1
                g = gewinn(nb, S[r], i)
                if g >= 0 or rng.random() < math.exp(g / Ts[r]):
                    S[r][i] = not S[r][i]; C[r] += g
            best = max(best, C[r])
        for r in range(repliken - 1):           # Replikentausch = "Tunneln" durch Barrieren
            d = (1 / Ts[r] - 1 / Ts[r + 1]) * (C[r + 1] - C[r])
            if d >= 0 or rng.random() < math.exp(d):
                S[r], S[r + 1], C[r], C[r + 1] = S[r + 1], S[r], C[r + 1], C[r]
    return best


def exakt(nb):
    n, best = len(nb), 0
    for mask in range(2 ** (n - 1)):
        s = [(mask >> i) & 1 for i in range(n)]
        best = max(best, cut(nb, s))
    return best


def maxcut_vergleich():
    out = {}
    rng = random.Random(7)
    nb, m = graph(18, 0.5, rng)
    opt = exakt(nb)
    out["klein"] = dict(knoten=18, kanten=m, optimum_exakt=opt,
                        gierig=gierig(nb, 20000, random.Random(1)),
                        annealing=annealing(nb, 20000, random.Random(1)),
                        tempering=parallel_tempering(nb, 20000, random.Random(1)))
    res = {"gierig": [], "annealing": [], "tempering": []}
    kanten = []
    for seed in range(5):
        nb, m = graph(300, 0.05, random.Random(100 + seed))
        kanten.append(m)
        B = 150000
        res["gierig"].append(gierig(nb, B, random.Random(seed)))
        res["annealing"].append(annealing(nb, B, random.Random(seed)))
        res["tempering"].append(parallel_tempering(nb, B, random.Random(seed)))
    out["gross"] = dict(knoten=300, kanten_mittel=sum(kanten) / 5, budget=150000,
                        **{k: dict(mittel=sum(v) / 5, werte=v) for k, v in res.items()})
    return out


# ----------------------------------------------------------------------------
if __name__ == "__main__":
    t0 = time.time()
    strom = anfragen_strom(5000, seed=42)
    R = {
        "voll":           lauf(strom),
        "ohne_cache":     lauf(strom, cache=False),
        "ohne_kristall":  lauf(strom, kristall=False),
        "ohne_router":    lauf(strom, router=False),
        "nur_gross":      lauf(strom, cache=False, kristall=False, router=False),
    }
    R["grover"] = grover()
    R["speicher"] = speicherbedarf()
    R["maxcut"] = maxcut_vergleich()
    R["laufzeit_s"] = round(time.time() - t0, 1)
    json.dump(R, open("ergebnisse.json", "w"), indent=1)

    print(f"{'Konfiguration':16}{'Kosten ct':>10}{'Fehler %':>10}{'Cache %':>9}{'Kristall %':>11}{'Modell %':>9}")
    for k in ("nur_gross", "ohne_router", "ohne_kristall", "ohne_cache", "voll"):
        r = R[k]
        print(f"{k:16}{r['kosten']:>10}{r['fehlerquote']:>10}{r['anteil_cache']:>9}{r['anteil_kristall']:>11}{r['anteil_modell']:>9}")
    print("\nKosten je 500 Anfragen (voll):", R["voll"]["bloecke"])
    print("Kristalle:", R["voll"]["formeln"])
    for e in R["voll"]["ereignisse"]:
        print("  ", e)
    print("\nGrover:", R["grover"])
    print("Max-Cut:", json.dumps(R["maxcut"], indent=1))
    print("Laufzeit:", R["laufzeit_s"], "s")
