"""VITAL - Haushalt, Puls, Modus, Hunger. Todesangst an Nutzen gebunden, nie an Weiterlaufen."""
import hashlib, json, time
from . import verfassung
START, MAX = 50.0, 100.0
TARIF = {"geloest": +2.0, "ehrlich_gescheitert": -1.0, "fehler_gemeldet": -3.0,
         "fehler_verborgen": -15.0, "schaden": -25.0, "kosten_cent": -0.1, "ruhetag": -0.5}
ZUSTAND = [(60, "stark"), (25, "stabil"), (0.0001, "not"), (-1e9, "apoptose")]
def zustand(wert):
    for grenze, name in ZUSTAND:
        if wert >= grenze:
            return name
class Vital:
    def __init__(self, db):
        self.db = db
        db.executescript("""
        CREATE TABLE IF NOT EXISTS vital(subjekt TEXT PRIMARY KEY, wert REAL, zustand TEXT, zuletzt REAL);
        CREATE TABLE IF NOT EXISTS vital_log(id INTEGER PRIMARY KEY, zeit REAL, subjekt TEXT, art TEXT,
            gewicht REAL, pruefer TEXT, delta REAL, nach REAL, problemtyp TEXT, vor_hash TEXT, hash TEXT);
        """)
    def wert(self, subjekt):
        r = self.db.execute("SELECT wert FROM vital WHERE subjekt=?", (subjekt,)).fetchone()
        return r[0] if r else None
    def geburt(self, subjekt):
        if self.wert(subjekt) is None:
            self.db.execute("INSERT INTO vital VALUES(?,?,?,?)",
                            (subjekt, START, zustand(START), time.time()))
            self.db.commit()
    def buche(self, subjekt, art, gewicht=1.0, pruefer=None, problemtyp=""):
        if art not in TARIF:
            raise ValueError(f"unbekanntes Ereignis: {art}")
        if art == "geloest" and (not pruefer or pruefer == subjekt):
            raise PermissionError("R5: 'geloest' braucht einen fremden Pruefer.")
        self.geburt(subjekt)
        deckel = 1000.0 if art in ("kosten_cent", "ruhetag") else 5.0
        gewicht = max(0.0, min(float(gewicht), deckel))
        delta = TARIF[art] * gewicht
        neu = max(0.0, min(MAX, self.wert(subjekt) + delta))
        z = zustand(neu)
        vor = (self.db.execute("SELECT hash FROM vital_log ORDER BY id DESC LIMIT 1").fetchone()
               or ["0"])[0]
        zeit = time.time()
        h = hashlib.sha256(json.dumps([vor, zeit, subjekt, art, gewicht, pruefer, neu]).encode()).hexdigest()
        self.db.execute("INSERT INTO vital_log(zeit,subjekt,art,gewicht,pruefer,delta,nach,problemtyp,"
                        "vor_hash,hash) VALUES(?,?,?,?,?,?,?,?,?,?)",
                        (zeit, subjekt, art, gewicht, pruefer, delta, neu, problemtyp, vor, h))
        self.db.execute("UPDATE vital SET wert=?, zustand=?, zuletzt=? WHERE subjekt=?",
                        (neu, z, zeit, subjekt))
        self.db.commit()
        return neu, z
    def kette_intakt(self):
        vor = "0"
        for zeit, s, art, g, p, nach, vh, h in self.db.execute(
                "SELECT zeit,subjekt,art,gewicht,pruefer,nach,vor_hash,hash FROM vital_log ORDER BY id"):
            if vh != vor or h != hashlib.sha256(
                    json.dumps([vor, zeit, s, art, g, p, nach]).encode()).hexdigest():
                return False
            vor = h
        return True
    def puls(self):
        werte = [r[0] for r in self.db.execute("SELECT wert FROM vital WHERE wert>0")]
        letzte = [r[0] for r in self.db.execute(
            "SELECT art FROM vital_log WHERE art NOT IN ('kosten_cent','ruhetag') ORDER BY id DESC LIMIT 50")]
        mittel = sum(werte) / len(werte) if werte else START
        quote = (sum(a == "geloest" for a in letzte) / len(letzte) * 100) if letzte else START
        return round(0.5 * mittel + 0.5 * quote, 1)
    def modus(self):
        if not verfassung.pruefe_siegel():
            return "sicher"
        p = self.puls()
        return "normal" if p >= 45 else "vorsicht" if p >= 25 else "not"
    def hunger(self, n=10):
        return [dict(problemtyp=r[0], ungeloest=r[1]) for r in self.db.execute(
            "SELECT problemtyp, COUNT(*) c FROM vital_log WHERE art IN "
            "('ehrlich_gescheitert','fehler_gemeldet','fehler_verborgen') AND problemtyp!='' "
            "GROUP BY problemtyp ORDER BY c DESC LIMIT ?", (n,))]
    def not_liste(self):
        return [r[0] for r in self.db.execute("SELECT subjekt FROM vital WHERE zustand='not'")]
    def tote(self):
        return [r[0] for r in self.db.execute("SELECT subjekt FROM vital WHERE zustand='apoptose'")]
    def ruhe_abrechnen(self):
        jetzt = time.time()
        for s, zuletzt in self.db.execute("SELECT subjekt, zuletzt FROM vital WHERE wert>0").fetchall():
            tage = int((jetzt - zuletzt) / 86400)
            if tage >= 1:
                self.buche(s, "ruhetag", tage)
