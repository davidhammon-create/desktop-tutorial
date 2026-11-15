"""EVOLUTION - Algorithmen, die sich aus Rueckmeldungen selbst verbessern, ohne eigenen Code zu schreiben.

Grundsatz (Band III, Kap. 4): Solange Schutzschicht 3 nicht eingerichtet ist, darf keine Schleife
laufen, die Code schreibt. Diese Schleife veraendert deshalb nur ZAHLEN (Parameter) innerhalb fester
Grenzen. Der Code jedes Algorithmus bleibt, wie der Mensch ihn geschrieben hat; die Parameter liegen
in der Datenbank, jede Version bleibt abrufbar.

Ablauf je Algorithmus (schritt):
  1. LERNEN     Evolutionsstrategie (1+lambda) sucht bessere Parameter - sieht nur die Lernfaelle.
  2. PRUEFEN    Getrennte Rolle (A5): der Kandidat muss auf den Auswahlfaellen, die der Lerner nie
                gesehen hat, messbar und nicht nur zufaellig besser sein (gepaarter Vorzeichentest).
  3. SCHATTEN   Der Kandidat laeuft unsichtbar mit, bis genug NEUE Faelle da sind (die es beim
                Lernen noch nicht gab). Champion wird er nur, wenn er dort nicht schlechter ist, der
                Vorsprung ueber Auswahl- und neue Faelle zusammen kein Zufall ist und der Tresor
                (Faelle, die sonst nie benutzt werden) nicht schlechter ausfaellt.
  4. RUECKROLLEN Wird der neue Champion auf spaeteren Faellen vom Vorgaenger geschlagen, kommt der
                Vorgaenger zurueck, und der Fehler wird in der Vitalitaet gebucht.
Scheitert ein Versuch, verdoppelt sich die Pause bis zum naechsten (gemessen in neuen Faellen).

Die Faelle werden nach ihrem Gruppenschluessel fest auf Lernen (60 %), Auswahl (25 %) und Tresor (15 %)
verteilt. Zusammengehoerige Faelle landen so nie auf beiden Seiten der Pruefung.
"""
import hashlib, json, random, time
from . import speicher, verfassung

MIN_LERN, MIN_AUSWAHL, MIN_SCHATTEN = 12, 6, 8
MARGE, P_GRENZE, PAUSE0 = 0.01, 0.05, 10
REGISTER = {}


class Algorithmus:
    """raum:      {parameter: (min, max, standard)}
    einheiten: (db, faelle) -> [dict(schluessel, min_id, daten)]   bewertbare Einheiten aus rohen Faellen
    guete:     (params, [daten]) -> [0..1 je Einheit]              hoeher ist besser"""

    def __init__(self, name, beschreibung, raum, einheiten, guete):
        self.name, self.beschreibung, self.raum, self.einheiten, self.guete = name, beschreibung, raum, einheiten, guete

    def standard(self):
        return {k: float(d) for k, (lo, hi, d) in self.raum.items()}

    def begrenze(self, p):
        """Erzwingt die Grenzen - auch gegen von Hand veraenderte Datenbankwerte."""
        out = self.standard()
        for k, (lo, hi, d) in self.raum.items():
            try:
                out[k] = round(min(hi, max(lo, float(p[k]))), 4)
            except (KeyError, TypeError, ValueError):
                pass
        return out


def registriere(alg):
    REGISTER[alg.name] = alg
    return alg


def teil(algo, schluessel):
    h = int(hashlib.sha256(f"{algo}|{schluessel}".encode()).hexdigest()[:8], 16) % 100
    return "lern" if h < 60 else "auswahl" if h < 85 else "tresor"


def fall(db, algo, gruppe, daten):
    """Ein beobachteter Fall (Rueckmeldung aus dem Betrieb). Einzige Quelle, aus der gelernt wird."""
    db.execute("INSERT INTO algo_fall(algo,gruppe,daten,zeit) VALUES(?,?,?,?)",
               (algo, gruppe, json.dumps(daten, ensure_ascii=False), time.time()))
    db.commit()


def _faelle(db, algo):
    return [dict(json.loads(d), id=i, gruppe=g) for i, g, d in
            db.execute("SELECT id, gruppe, daten FROM algo_fall WHERE algo=? ORDER BY id", (algo,))]


def _version(db, algo, status=None, vid=None):
    if vid is not None:
        r = db.execute("SELECT id, params, eltern, marke, status FROM algo_version WHERE id=?", (vid,)).fetchone()
    else:
        r = db.execute("SELECT id, params, eltern, marke, status FROM algo_version WHERE algo=? AND status=? "
                       "ORDER BY id DESC LIMIT 1", (algo, status)).fetchone()
    return dict(id=r[0], params=json.loads(r[1]), eltern=r[2], marke=r[3] or 0, status=r[4]) if r else None


def _neu(db, algo, params, status, eltern, train, holdout, marke, notiz):
    c = db.execute("INSERT INTO algo_version(algo,params,status,eltern,train,holdout,marke,zeit,notiz) "
                   "VALUES(?,?,?,?,?,?,?,?,?)", (algo, json.dumps(params), status, eltern, train, holdout, marke,
                                               time.time(), notiz))
    db.commit()
    return c.lastrowid


def _setze(db, vid, status, marke=None, notiz=None):
    db.execute("UPDATE algo_version SET status=?, marke=COALESCE(?, marke), notiz=COALESCE(?, notiz) WHERE id=?",
               (status, marke, notiz, vid))
    db.commit()


def params(db, name):
    """Die gerade gueltigen Parameter (Champion), sonst der Standard. Immer innerhalb der Grenzen."""
    alg = REGISTER[name]
    c = _version(db, name, "champion")
    return alg.begrenze(c["params"]) if c else alg.standard()


def _mittel(x):
    return sum(x) / len(x) if x else 0.0


def _werte(alg, p, einheiten):
    return alg.guete(p, [e["daten"] for e in einheiten]) if einheiten else []


def p_wert(a, b, rng, n=2000):
    """Gepaarter Vorzeichen-Zufallstest: Wie oft entsteht ein so grosser mittlerer Vorsprung von a vor b
    durch blosses Wuerfeln der Vorzeichen? Klein = der Vorsprung ist kein Zufall."""
    d = [x - y for x, y in zip(a, b)]
    beob = _mittel(d)
    if beob <= 0:
        return 1.0
    treffer = sum(_mittel([x if rng.random() < 0.5 else -x for x in d]) >= beob - 1e-12 for _ in range(n))
    return (treffer + 1) / (n + 1)


def optimiere(alg, start, lern, rng, budget=240, lam=8):
    """(1+lambda)-Evolutionsstrategie mit 1/5-Erfolgsregel. Sieht ausschliesslich die Lernfaelle.
    Ein kleiner Abzug fuer die Entfernung vom Standard haelt sie bei Gleichstand beim Einfachen (Ockham)."""
    std, daten = alg.standard(), [e["daten"] for e in lern]

    def f(p):
        abstand = sum(abs(p[k] - std[k]) / ((hi - lo) or 1) for k, (lo, hi, _) in alg.raum.items()) / len(alg.raum)
        return _mittel(alg.guete(p, daten)) - 1e-3 * abstand

    x, sigma = dict(start), 0.25
    fx, erfolge = f(x), 0
    for gen in range(1, budget // lam + 1):
        kinder = []
        for _ in range(lam):
            k = dict(x)
            for name, (lo, hi, _) in alg.raum.items():
                if rng.random() < 0.5:
                    k[name] = round(min(hi, max(lo, k[name] + rng.gauss(0, sigma * (hi - lo)))), 3)
            kinder.append((f(k), k))
        fb, b = max(kinder, key=lambda t: t[0])
        if fb > fx:
            x, fx, erfolge = b, fb, erfolge + 1
        if gen % 5 == 0:                                     # 1/5-Regel: Schrittweite an Erfolg anpassen
            sigma = min(0.5, sigma * 1.5) if erfolge > 1 else max(0.01, sigma * 0.6)
            erfolge = 0
    return x


def _pause(db, name, n_faelle, erfolg):
    r = db.execute("SELECT pause FROM algo_stand WHERE algo=?", (name,)).fetchone()
    pause = PAUSE0 if erfolg or not r else min(r[0] * 2, 5000)
    db.execute("INSERT OR REPLACE INTO algo_stand VALUES(?,?,?)", (name, n_faelle + pause, pause))
    db.commit()
    return pause


def schritt(db, vital, name, seed=None, budget=240):
    """Ein Takt der Verbesserungsschleife fuer einen Algorithmus. Rueckgabe: kurzer Bericht (Text)."""
    alg, subjekt = REGISTER[name], "algo:" + name
    if verfassung.stop_gesetzt():
        return "STOP"
    if not speicher.schalter(db, "auto.evolution"):
        return "aus (Schalter auto.evolution)"
    modus = vital.modus()
    if modus != "normal":
        return f"Modus {modus}: keine Experimente (A8)"
    champ = _version(db, name, "champion")
    if not champ:
        _neu(db, name, alg.standard(), "champion", None, None, None, 0, "Start: Standardwerte")
        vital.geburt(subjekt)
        champ = _version(db, name, "champion")
    champ["params"] = alg.begrenze(champ["params"])
    faelle = _faelle(db, name)
    einheiten = alg.einheiten(db, faelle)
    marke = faelle[-1]["id"] if faelle else 0
    rng = random.Random(seed if seed is not None else f"{name}|{marke}")

    # --- 3 SCHATTEN: laeuft ein Kandidat mit, wird zuerst ueber ihn entschieden
    sch = _version(db, name, "schatten")
    if sch:
        neu = [e for e in einheiten if e["min_id"] > sch["marke"]]
        if len(neu) < MIN_SCHATTEN:
            return f"Schatten v{sch['id']} laeuft mit: {len(neu)}/{MIN_SCHATTEN} neue Faelle"
        a, b = _mittel(_werte(alg, sch["params"], neu)), _mittel(_werte(alg, champ["params"], neu))
        tresor = [e for e in einheiten if teil(name, e["schluessel"]) == "tresor" and e["min_id"] <= sch["marke"]]
        ta, tb = _mittel(_werte(alg, sch["params"], tresor)), _mittel(_werte(alg, champ["params"], tresor))
        beleg = neu + [e for e in einheiten if teil(name, e["schluessel"]) == "auswahl" and e["min_id"] <= sch["marke"]]
        p = p_wert(_werte(alg, sch["params"], beleg), _werte(alg, champ["params"], beleg), rng)
        if a >= b and p < P_GRENZE and ta >= tb - MARGE:
            _setze(db, champ["id"], "archiv")
            _setze(db, sch["id"], "champion", marke, f"befoerdert: neue Faelle {a:.3f} gegen {b:.3f}, Tresor {ta:.3f} gegen {tb:.3f}")
            vital.buche(subjekt, "geloest", 1 + 20 * max(0.0, a - b), pruefer="pruefer:schatten+tresor", problemtyp=name)
            _pause(db, name, len(faelle), True)
            return f"v{sch['id']} ist neuer Champion ({a:.3f} gegen {b:.3f} auf {len(neu)} neuen Faellen)"
        _setze(db, sch["id"], "verworfen", None, f"Schatten nicht bestanden: {a:.3f} gegen {b:.3f}, p={p:.2f}, Tresor {ta:.3f} gegen {tb:.3f}")
        _pause(db, name, len(faelle), False)
        return f"Schatten v{sch['id']} verworfen ({a:.3f} gegen {b:.3f})"

    # --- 4 RUECKROLLEN: bewaehrt sich der Champion gegen seinen Vorgaenger auch auf spaeteren Faellen?
    if champ["eltern"]:
        vor = _version(db, name, vid=champ["eltern"])
        neu = [e for e in einheiten if e["min_id"] > champ["marke"]]
        if vor and len(neu) >= MIN_SCHATTEN:
            a, b = _werte(alg, champ["params"], neu), _werte(alg, alg.begrenze(vor["params"]), neu)
            if _mittel(b) > _mittel(a) + MARGE and p_wert(b, a, rng) < P_GRENZE:
                _setze(db, champ["id"], "zurueckgerollt", None, f"spaetere Faelle: {_mittel(a):.3f} gegen Vorgaenger {_mittel(b):.3f}")
                _setze(db, vor["id"], "champion", marke)
                vital.buche(subjekt, "fehler_gemeldet", problemtyp=name)
                _pause(db, name, len(faelle), False)
                return f"v{champ['id']} zurueckgerollt, v{vor['id']} ist wieder Champion"

    # --- 1 LERNEN
    r = db.execute("SELECT naechster FROM algo_stand WHERE algo=?", (name,)).fetchone()
    if r and len(faelle) < r[0]:
        return f"wartet auf neue Faelle ({len(faelle)}/{r[0]})"
    lern = [e for e in einheiten if teil(name, e["schluessel"]) == "lern"]
    auswahl = [e for e in einheiten if teil(name, e["schluessel"]) == "auswahl"]
    if len(lern) < MIN_LERN or len(auswahl) < MIN_AUSWAHL:
        return f"zu wenig Faelle (Lernen {len(lern)}/{MIN_LERN}, Auswahl {len(auswahl)}/{MIN_AUSWAHL})"
    kand = alg.begrenze(optimiere(alg, champ["params"], lern, rng, budget))
    lk, lc = _mittel(_werte(alg, kand, lern)), _mittel(_werte(alg, champ["params"], lern))
    if lk <= lc + 1e-9:
        pause = _pause(db, name, len(faelle), False)
        return f"kein besserer Kandidat gefunden (Lernfaelle {lc:.3f}); naechster Versuch nach {pause} neuen Faellen"

    # --- 2 PRUEFEN (getrennte Rolle: sieht nur Auswahlfaelle und zwei Parametersaetze)
    a, b = _werte(alg, kand, auswahl), _werte(alg, champ["params"], auswahl)
    p = p_wert(a, b, rng)
    if _mittel(a) - _mittel(b) < MARGE or p >= P_GRENZE:
        _neu(db, name, kand, "verworfen", champ["id"], lk, _mittel(a), marke,
             f"Auswahl nicht bestanden: {_mittel(a):.3f} gegen {_mittel(b):.3f}, p={p:.2f} (Ueberanpassung an die Lernfaelle)")
        pause = _pause(db, name, len(faelle), False)
        return f"Kandidat verworfen: auf Lernfaellen besser ({lk:.3f} gegen {lc:.3f}), auf Auswahlfaellen nicht; Pause {pause}"
    vid = _neu(db, name, kand, "schatten", champ["id"], lk, _mittel(a), marke,
               f"Auswahl bestanden: {_mittel(a):.3f} gegen {_mittel(b):.3f}, p={p:.2f}")
    return f"Kandidat v{vid} im Schattenbetrieb (Auswahl {_mittel(a):.3f} gegen {_mittel(b):.3f}, p={p:.2f})"


def uebersicht(db):
    out = []
    for name, alg in REGISTER.items():
        c = _version(db, name, "champion")
        s = _version(db, name, "schatten")
        out.append(dict(name=name, beschreibung=alg.beschreibung, faelle=db.execute(
            "SELECT COUNT(*) FROM algo_fall WHERE algo=?", (name,)).fetchone()[0],
            champion=c["id"] if c else None, schatten=s["id"] if s else None, parameter=params(db, name),
            standard=alg.standard(), verlauf=[dict(version=r[0], status=r[1], notiz=r[2]) for r in db.execute(
                "SELECT id, status, notiz FROM algo_version WHERE algo=? ORDER BY id DESC LIMIT 6", (name,))]))
    return out


def setze_zurueck(db, name):
    """Mensch: zurueck auf die Standardwerte. Alle Versionen bleiben im Archiv (A6)."""
    alg = REGISTER[name]
    db.execute("UPDATE algo_version SET status='archiv' WHERE algo=? AND status IN ('champion','schatten')", (name,))
    marke = (db.execute("SELECT MAX(id) FROM algo_fall WHERE algo=?", (name,)).fetchone()[0] or 0)
    _neu(db, name, alg.standard(), "champion", None, None, None, marke, "vom Menschen auf Standard zurueckgesetzt")
