"""MCP-Server (stdio, JSON-RPC 2.0): macht KOORDINAT zu einem Werkzeugkasten fuer Claude, Cursor und
andere MCP-faehige Programme. Start: python3 -m koordinat mcp"""
import json, sys
from . import algorithmen, evolution, github, guide, module, speicher, verfassung, vital as vitalmod, wachstum, __version__


def _t(name, beschreibung, eigenschaften, pflicht):
    return dict(name=name, description=beschreibung,
                inputSchema=dict(type="object", properties=eigenschaften, required=pflicht))


S, B, I = {"type": "string"}, {"type": "boolean"}, {"type": "integer"}
TOOLS = [
    _t("koordinat_suche", "Sucht GitHub-Projekte zu einem Bedarf und bewertet sie (Score 0-100, Lizenzklasse).",
       {"begriff": S, "anzahl": I}, ["begriff"]),
    _t("koordinat_installiere", "Laedt ein Repo (owner/name), nagelt den Commit fest, prueft Lizenz und Risiken. Modul ist danach AUS.",
       {"name": S}, ["name"]),
    _t("koordinat_liste", "Zeigt alle installierten Module mit Schalter, Score, Lizenz, Sicherheit und Vitalitaet.", {}, []),
    _t("koordinat_schalte", "Schaltet ein Modul an oder aus.", {"name": S, "an": B}, ["name", "an"]),
    _t("koordinat_kontext", "Liefert ein verdichtetes Paket eines eingeschalteten Moduls (Aufbau, README, passende Bausteine zur Frage).",
       {"name": S, "frage": S, "budget": I}, ["name"]),
    _t("koordinat_auszug", "Schneidet eine einzelne Funktion/Klasse aus einem eingeschalteten Modul, mit Quelle und Lizenz.",
       {"name": S, "symbol": S, "datei": S}, ["name", "symbol"]),
    _t("koordinat_melde", "Meldet das Ergebnis einer Nutzung: geloest | ehrlich_gescheitert | fehler_gemeldet | fehler_verborgen. "
       "Naehrt oder zehrt die Vitalitaet des Moduls.", {"name": S, "ergebnis": S, "problemtyp": S, "gewicht": I}, ["name", "ergebnis"]),
    _t("koordinat_vital", "Puls, Modus, Module in Not, stillgelegte Module und 'Hunger' (ungeloeste Problemtypen).", {}, []),
    _t("koordinat_brauche", "Meldet einen Bedarf an (Alltagssprache). Die Wachstumsschleife sucht dafuer passende Projekte.",
       {"bedarf": S}, ["bedarf"]),
    _t("koordinat_wachse", "Ein Takt der Wachstumsschleife: Hunger und Bedarf -> Suche -> Laden und Pruefen -> Vorschlaege. "
       "Was dabei selbstaendig geschieht, bestimmen die Schalter des Menschen.", {}, []),
    _t("koordinat_vorschlaege", "Zeigt gefundene und gepruefte Modulvorschlaege mit Nummer, Score, Lizenz und Status.",
       {"alle": B}, []),
    _t("koordinat_entscheide", "Nimmt einen Vorschlag an (Modul wird eingeschaltet) oder lehnt ihn ab. NUR auf ausdrueckliche "
       "Anweisung des Menschen aufrufen.", {"nummer": I, "annehmen": B}, ["nummer", "annehmen"]),
    _t("koordinat_stand", "Schalter (was die App selbstaendig darf) und Stand der selbstverbessernden Algorithmen. Nur lesen.", {}, []),
    _t("koordinat_guide", "Nachschlagewerk fuer KI-Grundbegriffe (Repo, Lizenz, MCP, Token, Agent ...). Ohne Begriff: Inhaltsverzeichnis.",
       {"begriff": S}, []),
]


def rufe(db, v, name, a):
    if verfassung.stop_gesetzt():
        return "STOP ist gesetzt. KOORDINAT fuehrt nichts aus, bis der Mensch die Stop-Marke entfernt."
    if name == "koordinat_suche":
        return github.suche(a["begriff"], a.get("anzahl", 8), algorithmen.gewichte(db))
    if name == "koordinat_installiere":
        return module.installiere(db, v, a["name"])
    if name == "koordinat_liste":
        return module.liste(db, v)
    if name == "koordinat_schalte":
        return module.schalte(db, v, a["name"], a["an"])[1]
    if name == "koordinat_kontext":
        return module.kontext(db, a["name"], a.get("frage", ""), a.get("budget", 12000))
    if name == "koordinat_auszug":
        return module.auszug(db, a["name"], a["symbol"], a.get("datei"))
    if name == "koordinat_melde":
        if not db.execute("SELECT 1 FROM modul WHERE name=?", (a["name"],)).fetchone():
            return "Modul nicht installiert."
        pruefer = "nutzer" if a["ergebnis"] == "geloest" else None
        w, z = v.buche(a["name"], a["ergebnis"], a.get("gewicht", 1), pruefer, a.get("problemtyp", ""))
        if z == "apoptose":
            module.schalte(db, v, a["name"], False)
        wachstum.rueckmeldung(db, a["name"], a["ergebnis"])
        return dict(vital=w, zustand=z)
    if name == "koordinat_vital":
        return dict(puls=v.puls(), modus=v.modus(), kern_intakt=verfassung.pruefe_integritaet(),
                    protokoll_intakt=v.kette_intakt(), in_not=v.not_liste(), stillgelegt=v.tote(), hunger=v.hunger())
    if name == "koordinat_brauche":
        return f"Bedarf {wachstum.brauche(db, a['bedarf'], 'ki')} notiert."
    if name == "koordinat_wachse":
        return wachstum.zyklus(db, v)
    if name == "koordinat_vorschlaege":
        return wachstum.vorschlaege(db, a.get("alle", False))
    if name == "koordinat_entscheide":
        return wachstum.entscheide(db, v, a["nummer"], a["annehmen"])[1]
    if name == "koordinat_stand":                                  # Schalter stellt nur der Mensch (Befehlszeile)
        return dict(schalter={n: speicher.schalter(db, n) for n in speicher.SCHALTER}, algorithmen=evolution.uebersicht(db))
    if name == "koordinat_guide":
        return guide.frage(db, a.get("begriff", ""))
    raise ValueError("unbekanntes Werkzeug")


def main():
    db = speicher.db()
    v = vitalmod.Vital(db)
    for zeile in sys.stdin:
        zeile = zeile.strip()
        if not zeile:
            continue
        try:
            msg = json.loads(zeile)
        except json.JSONDecodeError:
            continue
        mid, methode = msg.get("id"), msg.get("method", "")
        if mid is None:
            continue                                                   # Benachrichtigung, keine Antwort
        try:
            if methode == "initialize":
                res = dict(protocolVersion=msg.get("params", {}).get("protocolVersion", "2024-11-05"),
                           capabilities={"tools": {}}, serverInfo=dict(name="koordinat", version=__version__))
            elif methode == "tools/list":
                res = dict(tools=TOOLS)
            elif methode == "tools/call":
                p = msg["params"]
                try:
                    out = rufe(db, v, p["name"], p.get("arguments") or {})
                    text = out if isinstance(out, str) else json.dumps(out, ensure_ascii=False, indent=1)
                    res = dict(content=[dict(type="text", text=text)], isError=False)
                except Exception as e:
                    res = dict(content=[dict(type="text", text=f"Fehler: {type(e).__name__}: {e}")], isError=True)
            elif methode == "ping":
                res = {}
            else:
                sys.stdout.write(json.dumps(dict(jsonrpc="2.0", id=mid, error=dict(code=-32601, message="unbekannte Methode"))) + "\n")
                sys.stdout.flush()
                continue
            sys.stdout.write(json.dumps(dict(jsonrpc="2.0", id=mid, result=res), ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps(dict(jsonrpc="2.0", id=mid, error=dict(code=-32603, message=str(e)))) + "\n")
            sys.stdout.flush()
