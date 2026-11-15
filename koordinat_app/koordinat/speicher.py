"""Speicher: eine SQLite-Datei in KOORDINAT_HOME. Tabellen des Fundaments, der Wachstumsschleife,
der Algorithmen-Evolution und die Schalter fuer alles, was die App selbstaendig tun darf."""
import json, pathlib, sqlite3, time
from . import verfassung

# Schalter: (Standard, Erklaerung). Nur der Mensch stellt sie um (Befehlszeile), nie die KI ueber MCP.
SCHALTER = {
    "auto.suche":       (1, "Hunger und gemeldeter Bedarf loesen selbstaendig eine GitHub-Suche aus"),
    "auto.laden":       (1, "die besten Treffer werden selbstaendig geladen und geprueft (bleiben AUS)"),
    "auto.einschalten": (0, "geladene Module mit freier Lizenz, bestandenem Scan und hohem Score gehen von selbst AN"),
    "auto.entdecken":   (1, "der Katalog waechst selbstaendig um neue KI-Werkzeuge von GitHub"),
    "auto.evolution":   (1, "eigene Algorithmen (Bewertung, Rangfolge) verbessern sich aus Rueckmeldungen"),
}

SCHEMA = """
CREATE TABLE IF NOT EXISTS modul(name TEXT PRIMARY KEY, commit_hash TEXT, lizenz TEXT,
    lizenzklasse TEXT, score INTEGER, sterne INTEGER, stack TEXT, sicherheit TEXT, befunde TEXT,
    schalter INTEGER DEFAULT 0, pfad TEXT, beschreibung TEXT, installiert REAL);
CREATE TABLE IF NOT EXISTS einstellung(name TEXT PRIMARY KEY, wert TEXT);
CREATE TABLE IF NOT EXISTS bedarf(id INTEGER PRIMARY KEY, text TEXT, anfrage TEXT, quelle TEXT, status TEXT, zeit REAL);
CREATE TABLE IF NOT EXISTS hunger_stand(problemtyp TEXT PRIMARY KEY, stand INTEGER);
CREATE TABLE IF NOT EXISTS vorschlag(id INTEGER PRIMARY KEY, bedarf_id INTEGER, repo TEXT, score INTEGER, meta TEXT,
    merkmale TEXT, status TEXT, grund TEXT, zeit REAL);
CREATE TABLE IF NOT EXISTS katalog(repo TEXT PRIMARY KEY, kategorie TEXT, zweck TEXT, sterne INTEGER, lizenz TEXT,
    lizenzklasse TEXT, score INTEGER, quelle TEXT, zeit REAL);
CREATE TABLE IF NOT EXISTS wachstum_log(id INTEGER PRIMARY KEY, zeit REAL, bericht TEXT);
CREATE TABLE IF NOT EXISTS kontext_frage(modul TEXT PRIMARY KEY, frage TEXT, zeit REAL);
CREATE TABLE IF NOT EXISTS algo_fall(id INTEGER PRIMARY KEY, algo TEXT, gruppe TEXT, daten TEXT, zeit REAL);
CREATE TABLE IF NOT EXISTS algo_version(id INTEGER PRIMARY KEY, algo TEXT, params TEXT, status TEXT, eltern INTEGER,
    train REAL, holdout REAL, marke INTEGER, zeit REAL, notiz TEXT);
CREATE TABLE IF NOT EXISTS algo_stand(algo TEXT PRIMARY KEY, naechster INTEGER, pause INTEGER);
CREATE TABLE IF NOT EXISTS guide_luecke(begriff TEXT PRIMARY KEY, anzahl INTEGER, zeit REAL);
"""


def db():
    verfassung.HEIM.mkdir(parents=True, exist_ok=True)
    (verfassung.HEIM / "module").mkdir(exist_ok=True)
    c = sqlite3.connect(verfassung.HEIM / "koordinat.db")
    c.executescript(SCHEMA)
    if not c.execute("SELECT 1 FROM katalog LIMIT 1").fetchone():          # Startkatalog einmalig uebernehmen
        start = json.loads((pathlib.Path(__file__).parent / "katalog.json").read_text())
        c.executemany("INSERT OR IGNORE INTO katalog(repo,kategorie,zweck,quelle,zeit) VALUES(?,?,?,?,?)",
                      [(e["repo"], e["kategorie"], e["zweck"], "start", time.time()) for e in start])
    c.commit()
    return c


def schalter(db, name):
    if name not in SCHALTER:
        raise KeyError(f"unbekannter Schalter: {name}")
    r = db.execute("SELECT wert FROM einstellung WHERE name=?", (name,)).fetchone()
    return bool(int(r[0])) if r else bool(SCHALTER[name][0])


def setze_schalter(db, name, an):
    if name not in SCHALTER:
        raise KeyError(f"unbekannter Schalter: {name}")
    db.execute("INSERT OR REPLACE INTO einstellung VALUES(?,?)", (name, "1" if an else "0"))
    db.commit()


def merke(db, name, wert=None):
    """Kleiner Notizzettel fuer Zeiger und Zaehler (kein Schalter)."""
    if wert is None:
        r = db.execute("SELECT wert FROM einstellung WHERE name=?", ("_" + name,)).fetchone()
        return r[0] if r else None
    db.execute("INSERT OR REPLACE INTO einstellung VALUES(?,?)", ("_" + name, str(wert)))
    db.commit()
