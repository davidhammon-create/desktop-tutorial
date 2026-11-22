"""MCP-Server (stdio, JSON-RPC 2.0)."""
import json, sys
from . import (algorithmen, apireg, erklaeren, evolution, github, guide, haltung, leitfaden,
               modelle, module, passung, planer, speicher, trace, verfassung, vital as vitalmod,
               wachstum, werkstatt, __version__)
def _t(n, b, e, p):
    return dict(name=n, description=b, inputSchema=dict(type="object", properties=e, required=p))
S, B, I = {"type": "string"}, {"type": "boolean"}, {"type": "integer"}
TOOLS = [
    _t("koordinat_mach", "Auftrag planen und fahren.", {"auftrag": S, "ja": B, "trocken": B}, ["auftrag"]),
    _t("koordinat_lauf", "Ablauf fahren.", {"ablauf": S, "ja": B}, ["ablauf"]),
    _t("koordinat_weiter", "Lauf fortsetzen.", {"lauf": I}, ["lauf"]),
    _t("koordinat_laeufe", "Laeufe.", {}, []),
    _t("koordinat_laufstand", "Schritte eines Laufs.", {"lauf": I}, ["lauf"]),
    _t("koordinat_trace", "Spur mit Erklaerungen.", {"lauf": I}, []),
    _t("koordinat_haltung", "Verhaltensprofil. roh=true zeigt den rohen Namen.", {"roh": B}, []),
    _t("koordinat_modelle", "Modelle nach Haerte und Staerke.", {}, []),
    _t("koordinat_erklaere", "Begriff in drei Stufen.", {"begriff": S, "stufe": I}, ["begriff"]),
    _t("koordinat_pruefe", "Prueffrage beantworten.", {"thema": S, "antwort": S}, ["thema", "antwort"]),
    _t("koordinat_pfad", "Lehrplan.", {"ziel": S}, ["ziel"]),
    _t("koordinat_guide", "Nachschlagewerk.", {"begriff": S}, []),
    _t("koordinat_suche", "GitHub durchsuchen.", {"begriff": S, "anzahl": I}, ["begriff"]),
    _t("koordinat_installiere", "Repo laden und pruefen.", {"name": S}, ["name"]),
    _t("koordinat_liste", "Module mit Schalter.", {}, []),
    _t("koordinat_schalte", "Modul an oder aus.", {"name": S, "an": B}, ["name", "an"]),
    _t("koordinat_passung", "Passende Module.", {"problemtyp": S}, ["problemtyp"]),
    _t("koordinat_aktiviere", "Bestpassendes an, Rest aus.", {"problemtyp": S}, ["problemtyp"]),
    _t("koordinat_kontext", "Kontextpaket.", {"name": S, "frage": S}, ["name"]),
    _t("koordinat_auszug", "Funktion herausschneiden.", {"name": S, "symbol": S}, ["name", "symbol"]),
    _t("koordinat_melde", "Ergebnis melden.", {"name": S, "ergebnis": S, "problemtyp": S}, ["name", "ergebnis"]),
    _t("koordinat_vital", "Puls, Modus, Hunger.", {}, []),
    _t("koordinat_brauche", "Bedarf anmelden.", {"bedarf": S}, ["bedarf"]),
    _t("koordinat_wachse", "Ein Takt.", {}, []),
    _t("koordinat_erstlauf", "Erster Start.", {}, []),
    _t("koordinat_vorschlaege", "Vorschlaege.", {"alle": B}, []),
    _t("koordinat_entscheide", "Vorschlag annehmen oder ablehnen.", {"nummer": I, "annehmen": B},
       ["nummer", "annehmen"]),
    _t("koordinat_stand", "Schalter, Algorithmen, Budget.", {}, []),
    _t("koordinat_api_eintragen", "Anbieter einsortieren.",
       {"name": S, "faehigkeit": S, "stufe": I, "preis_cent": {"type": "number"}},
       ["name", "faehigkeit", "stufe", "preis_cent"]),
    _t("koordinat_api_liste", "Anbieter nach Kosten.", {"faehigkeit": S}, []),
    _t("koordinat_api_ampel", "Budgetampel.", {}, []),
    _t("koordinat_api_waehle", "Billigste ausreichende Stufe.", {"faehigkeit": S}, ["faehigkeit"]),
    _t("koordinat_api_verbrauch", "Cent buchen.", {"name": S, "einheiten": {"type": "number"}}, ["name"]),
    _t("koordinat_budget", "Budget in Cent.", {"cent": I}, ["cent"]),
]
def rufe(db, v, name, a):
    if verfassung.stop_gesetzt() and name not in ("koordinat_vital", "koordinat_haltung"):
        return "STOP ist gesetzt."
    if name == "koordinat_mach":
        lauf, m = werkstatt.starte(db, v, planer.plan(a["auftrag"]), a.get("ja", False), a.get("trocken", False))
        return m + ("\n\n" + werkstatt.stand(db, lauf) if lauf else "")
    if name == "koordinat_lauf":
        x = next((q for q in planer.vorlagen() if q["id"] == a["ablauf"]), None)
        return werkstatt.starte(db, v, dict(quelle="vorlage", passung=9, ablauf=x), a.get("ja", False))[1] if x else "unbekannt"
    if name == "koordinat_weiter":
        return werkstatt.weiter(db, v, a["lauf"])[1]
    if name == "koordinat_laeufe":
        return werkstatt.laeufe(db)
    if name == "koordinat_laufstand":
        return werkstatt.stand(db, a["lauf"])
    if name == "koordinat_trace":
        return trace.zeige(db, a.get("lauf"))
    if name == "koordinat_haltung":
        return "\n".join(haltung.tabelle(a.get("roh", False)))
    if name == "koordinat_modelle":
        return modelle.bericht()
    if name == "koordinat_erklaere":
        return erklaeren.erklaere(db, a["begriff"], a.get("stufe"))
    if name == "koordinat_pruefe":
        ok, t = erklaeren.pruefe(db, a["thema"], a["antwort"])
        return dict(bestanden=ok, rueckmeldung=t)
    if name == "koordinat_pfad":
        return erklaeren.pfad(db, a["ziel"])
    if name == "koordinat_guide":
        return guide.frage(db, a.get("begriff", ""))
    if name == "koordinat_suche":
        return github.suche(a["begriff"], a.get("anzahl", 8), algorithmen.gewichte(db))
    if name == "koordinat_installiere":
        return module.installiere(db, v, a["name"])
    if name == "koordinat_liste":
        return module.liste(db, v)
    if name == "koordinat_schalte":
        return module.schalte(db, v, a["name"], a["an"])[1]
    if name == "koordinat_passung":
        return passung.kandidaten(db, a["problemtyp"], v)
    if name == "koordinat_aktiviere":
        return passung.aktiviere_fuer(db, v, a["problemtyp"])[1]
    if name == "koordinat_kontext":
        return module.kontext(db, a["name"], a.get("frage", ""))
    if name == "koordinat_auszug":
        return module.auszug(db, a["name"], a["symbol"])
    if name == "koordinat_melde":
        if not db.execute("SELECT 1 FROM modul WHERE name=?", (a["name"],)).fetchone():
            return "Modul nicht installiert."
        w, z = v.buche(a["name"], a["ergebnis"], 1,
                       "nutzer" if a["ergebnis"] == "geloest" else None, a.get("problemtyp", ""))
        wachstum.rueckmeldung(db, a["name"], a["ergebnis"])
        return dict(vital=w, zustand=z)
    if name == "koordinat_vital":
        return dict(puls=v.puls(), modus=v.modus(), siegel=verfassung.stand(), hunger=v.hunger())
    if name == "koordinat_brauche":
        return f"Bedarf {wachstum.brauche(db, a['bedarf'], 'ki')} notiert."
    if name == "koordinat_wachse":
        return wachstum.zyklus(db, v)
    if name == "koordinat_erstlauf":
        return wachstum.erstlauf(db, v)
    if name == "koordinat_vorschlaege":
        return wachstum.vorschlaege(db, a.get("alle", False))
    if name == "koordinat_entscheide":
        return wachstum.entscheide(db, v, a["nummer"], a["annehmen"])[1]
    if name == "koordinat_stand":
        return dict(schalter={n: speicher.schalter(db, n) for n in speicher.SCHALTER},
                    algorithmen=evolution.uebersicht(db), budget_cent=speicher.budget(db),
                    modelle=modelle.profil(), siegel=verfassung.stand())
    if name == "koordinat_api_eintragen":
        return apireg.eintragen(db, a["name"], a["faehigkeit"], a["stufe"], a["preis_cent"])
    if name == "koordinat_api_liste":
        return apireg.liste(db, a.get("faehigkeit"))
    if name == "koordinat_api_ampel":
        return dict(ampel=apireg.ampel(db), verbraucht_cent=apireg.monat_cent(db), budget_cent=speicher.budget(db))
    if name == "koordinat_api_waehle":
        return apireg.waehle(db, a["faehigkeit"])
    if name == "koordinat_api_verbrauch":
        return apireg.verbrauch(db, v, a["name"], a.get("einheiten", 1))[1]
    if name == "koordinat_budget":
        speicher.setze_budget(db, a["cent"])
        return f"Budget {a['cent']} Cent."
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
            continue
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
                    res = dict(content=[dict(type="text", text=out if isinstance(out, str)
                                             else json.dumps(out, ensure_ascii=False, indent=1))],
                               isError=False)
                except Exception as e:
                    res = dict(content=[dict(type="text", text=f"Fehler: {type(e).__name__}: {e}")],
                               isError=True)
            elif methode == "ping":
                res = {}
            else:
                sys.stdout.write(json.dumps(dict(jsonrpc="2.0", id=mid,
                                                 error=dict(code=-32601, message="unbekannt"))) + "\n")
                sys.stdout.flush()
                continue
            sys.stdout.write(json.dumps(dict(jsonrpc="2.0", id=mid, result=res), ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps(dict(jsonrpc="2.0", id=mid,
                                             error=dict(code=-32603, message=str(e)))) + "\n")
            sys.stdout.flush()
