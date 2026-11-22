"""Befehlszeile: python3 -m koordinat <befehl>"""
import getpass, json, sys
from . import (algorithmen, apireg, erklaeren, evolution, github, guide, haltung, leitfaden,
               modelle, module, passung, planer, speicher, trace, verfassung, vital as vitalmod,
               wachstum, werkstatt)
HILFE = """KOORDINAT 2.1
  start | panel [port] | mcp
  mach "<auftrag>" [--ja] [--trocken] | lauf <ablauf> [--ja] [--trocken]
  weiter <lauf> | abbrechen <lauf> | laeufe | laeufe-vorlagen | stand <lauf> | trace [lauf]
  haltung [ehrlich] | modelle
  kern [stand|festziehen|oeffnen|schluessel]
  erklaere <begriff> [stufe] | pruefe <thema> <antwort> | pfad <ziel> | guide [begriff]
  suche "<bedarf>" | installiere <owner/name> | liste | an <name> | aus <name>
  passung <typ> | aktiviere <typ> | kontext <name> ["frage"] | auszug <name> <symbol>
  melde <name> <ergebnis> | vital | brauche "<bedarf>" | wachse [takt]
  erstlauf | vorschlaege [alle] | annehmen <nr> | ablehnen <nr>
  schalter [name an|aus] | algorithmen [zuruecksetzen <name>]
  api [liste|ampel|eintragen|waehle|verbrauch|budget] ...
  los "<anliegen>" | weiter-leitfaden | leitfaden
  verfassung | entwicklung [an|aus] | stop | fortsetzen"""
def bericht(r):
    if r.get("status") != "ok":
        return r["status"]
    z = [f"Takt im Modus {r['modus']}:"]
    for k, t in (("geladen", "geladen"), ("eingeschaltet", "von selbst an"),
                 ("gesperrt", "nicht nutzbar"), ("stillgelegt", "stillgelegt"), ("entdeckt", "neu im Katalog")):
        if r[k]:
            z.append(f" {t}: {', '.join(r[k])}")
    for n, t in r["evolution"].items():
        z.append(f" Algorithmus {n}: {t}")
    z += [" Hinweis: " + h for h in r["hinweise"]]
    z.append(f" {r['wartet_auf_dich']} Vorschlaege warten.")
    return "\n".join(z)
def kern(a):
    if not a or a[0] == "stand":
        print(verfassung.stand())
    elif a[0] == "festziehen":
        sch = getpass.getpass("Schluessel (leer = keiner): ") or None
        try:
            verfassung.festziehen(input(f'Woertlich "{verfassung.SATZ}": '), sch)
            print("Festgezogen.")
        except PermissionError as e:
            print("Abgelehnt:", e)
    elif a[0] == "oeffnen":
        sch = getpass.getpass("Schluessel (leer = keiner): ") or None
        try:
            verfassung.oeffnen(sch)
            print("Geoeffnet, Kern frei bearbeitbar.")
        except PermissionError as e:
            print("Abgelehnt:", e)
    elif a[0] == "schluessel":
        alt = getpass.getpass("Bisheriger: ") if verfassung.besitzer_gesetzt() else None
        try:
            verfassung.setze_besitzer(getpass.getpass("Neuer: "), alt)
            print("Gesetzt.")
        except (PermissionError, ValueError) as e:
            print("Abgelehnt:", e)
    else:
        print("kern [stand|festziehen|oeffnen|schluessel]")
def main(argv):
    if not argv or argv[0] in ("-h", "hilfe", "--help"):
        print(HILFE)
        return
    b = argv[0]
    a = [x for x in argv[1:] if not x.startswith("--")]
    ja, trocken = "--ja" in argv, "--trocken" in argv
    if b == "stop":
        verfassung.abschalten()
        print("STOP gesetzt.")
        return
    if b == "fortsetzen":
        verfassung.STOP.unlink(missing_ok=True)
        print("Stop-Marke entfernt.")
        return
    if b == "verfassung":
        print("ZIEL\n " + verfassung.ZIEL + "\n")
        for t, x in verfassung.REGELN:
            print(f"{t}\n {x}")
        return
    if b == "haltung":
        print("\n".join(haltung.tabelle(bool(a))))
        return
    if b == "modelle":
        print(modelle.bericht())
        return
    if b == "kern":
        kern(a)
        return
    if b == "entwicklung":
        if a and a[0] in ("an", "aus"):
            verfassung.entwicklung(a[0] == "an")
        print("Entwurfsmodus:", "AN" if verfassung.entwicklungsmodus() else "aus")
        return
    if b == "mcp":
        from . import mcp_server
        mcp_server.main()
        return
    if verfassung.stop_gesetzt() and b != "vital":
        print("STOP gesetzt. 'fortsetzen' hebt auf.")
        return
    db = speicher.db()
    v = vitalmod.Vital(db)
    if b == "start":
        from . import shell
        shell.start(db, v)
    elif b == "panel":
        from . import panel
        panel.starte(int(a[0]) if a else 8712)
    elif b == "mach":
        p = planer.plan(" ".join(a))
        print(f"Plan aus {p['quelle']}: {p['ablauf']['titel']}")
        for i, s in enumerate(p["ablauf"]["schritte"], 1):
            print(f" {i}. {s['titel']} [{s['art']}] {s.get('erklaerung', '')}")
        if not ja and input("\nStart? j/n ").strip().lower() != "j":
            return
        print(werkstatt.starte(db, v, p, ja, trocken)[1])
    elif b == "lauf":
        x = next((q for q in planer.vorlagen() if q["id"] == a[0]), None)
        if not x:
            print("Unbekannt. 'laeufe-vorlagen' zeigt alle.")
            return
        print(werkstatt.starte(db, v, dict(quelle="vorlage", passung=9, ablauf=x), ja, trocken)[1])
    elif b == "laeufe-vorlagen":
        for x in planer.vorlagen():
            print(f" {x['id']:<12} {x['titel']}")
    elif b == "weiter":
        print(werkstatt.weiter(db, v, int(a[0]), ja, trocken)[1])
    elif b == "abbrechen":
        print(werkstatt.abbrechen(db, int(a[0])))
    elif b == "laeufe":
        for l in werkstatt.laeufe(db):
            print(f" #{l['id']:<4} {l['stand']:<10} {l['schritt']:>2}  {l['titel']}")
    elif b == "stand":
        print(werkstatt.stand(db, int(a[0])))
    elif b == "trace":
        print(trace.zeige(db, int(a[0]) if a and a[0].isdigit() else None))
    elif b == "erklaere":
        st = int(a[-1]) if a and a[-1].isdigit() else None
        print(erklaeren.erklaere(db, " ".join(a[:-1] if st else a), st))
    elif b == "pruefe":
        print(erklaeren.pruefe(db, a[0], " ".join(a[1:]))[1])
    elif b == "pfad":
        print(" -> ".join(erklaeren.pfad(db, " ".join(a))))
    elif b == "guide":
        print(guide.frage(db, " ".join(a)))
    elif b == "suche":
        for t in github.suche(" ".join(a), 8, algorithmen.gewichte(db)):
            print(f"{t['score']:>3} {t['name']:<42} {t['sterne']:<7} {t['lizenz'] or 'KEINE':<12} "
                  f"{t['beschreibung'][:60]}")
    elif b == "installiere":
        m = module.installiere(db, v, a[0])
        print(f"{m['name']} @ {m['commit'][:10]} Lizenz {m['lizenz'] or 'KEINE'} "
              f"({m['lizenzklasse']}) Sicherheit {m['sicherheit']} Score {m['score']}")
    elif b == "liste":
        for m in module.liste(db, v):
            print(f"{'AN ' if m['an'] else 'aus'} {m['name']:<38} Score {m['score']:>3} "
                  f"{m['lizenz'] or 'KEINE':<12} {m['sicherheit']:<9} Vital {m['vital']}")
    elif b in ("an", "aus"):
        print(module.schalte(db, v, a[0], b == "an")[1])
    elif b == "passung":
        for k in passung.kandidaten(db, " ".join(a), v):
            print(f"{k['passung']:.2f} {k['name']:<38} {'AN' if k['an'] else 'aus'}")
    elif b == "aktiviere":
        print(passung.aktiviere_fuer(db, v, " ".join(a))[1])
    elif b == "kontext":
        print(module.kontext(db, a[0], " ".join(a[1:])))
    elif b == "auszug":
        print(module.auszug(db, a[0], a[1]))
    elif b == "melde":
        if not db.execute("SELECT 1 FROM modul WHERE name=?", (a[0],)).fetchone():
            print("Modul nicht installiert.")
            return
        w, z = v.buche(a[0], a[1], 1, "nutzer" if a[1] == "geloest" else None, " ".join(a[2:]))
        wachstum.rueckmeldung(db, a[0], a[1])
        print(f"Vital {w:.1f} ({z})")
    elif b == "vital":
        print(f"Puls {v.puls()} Modus {v.modus()}  Kern {verfassung.stand()}")
        print("In Not:", v.not_liste() or "-")
        print("Hunger:", v.hunger() or "-")
    elif b == "brauche":
        print(f"Bedarf {wachstum.brauche(db, ' '.join(a))} notiert.")
    elif b == "wachse":
        if a:
            wachstum.dauerlauf(db, v, float(a[0]), float(a[1]) if len(a) > 1 else 0,
                               lambda r: print(bericht(r), flush=True))
        else:
            print(bericht(wachstum.zyklus(db, v)))
    elif b == "erstlauf":
        r = wachstum.erstlauf(db, v)
        print(f"{len(r['saat'])} Katalogeintraege, {len(r['api'])} Anbieter einsortiert.")
        print(bericht(r["takt"]))
    elif b == "vorschlaege":
        for x in wachstum.vorschlaege(db, bool(a)):
            print(f"{x['id']:>4} {x['status']:<11} {x['repo']:<40} Score {x['score']:>3} fuer: {x['bedarf'][:30]}")
    elif b in ("annehmen", "ablehnen"):
        print(wachstum.entscheide(db, v, int(a[0]), b == "annehmen")[1])
    elif b == "schalter":
        if len(a) == 2 and a[1] in ("an", "aus"):
            speicher.setze_schalter(db, a[0], a[1] == "an")
        for n, (_, text) in speicher.SCHALTER.items():
            print(f"{'AN ' if speicher.schalter(db, n) else 'aus'} {n:<18} {text}")
    elif b == "algorithmen":
        if len(a) == 2 and a[0] == "zuruecksetzen":
            evolution.setze_zurueck(db, a[1])
        for x in evolution.uebersicht(db):
            print(f"{x['name']}: {x['faelle']} Faelle, Champion v{x['champion'] or 0}")
    elif b == "api":
        u = a[0] if a else "liste"
        if u == "liste":
            print(apireg.bericht(db))
        elif u == "ampel":
            print(f"Ampel {apireg.ampel(db)}  verbraucht {apireg.monat_cent(db) / 100:.2f} EUR")
        elif u == "budget":
            speicher.setze_budget(db, int(a[1]))
            print(f"Budget {a[1]} Cent.")
        elif u == "eintragen":
            apireg.eintragen(db, a[1], a[2], int(a[3]), float(a[4]))
            print("Eingetragen.")
        elif u == "waehle":
            e = apireg.waehle(db, a[1])
            print(e["name"] if e else "keiner")
        elif u == "verbrauch":
            print(apireg.verbrauch(db, v, a[1], float(a[2]) if len(a) > 2 else 1)[1])
    elif b == "los":
        print(leitfaden.los(db, " ".join(a)))
    elif b == "weiter-leitfaden":
        print(leitfaden.weiter(db))
    elif b == "leitfaden":
        print(leitfaden.inhalt())
    elif b == "entdecke":
        print(len(wachstum.entdecke(db)), "neu.")
    else:
        print(HILFE)
if __name__ == "__main__":
    main(sys.argv[1:])
