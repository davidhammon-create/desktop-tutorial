"""SHELL - der Kasten. Fuenf Griffe, sonst nichts."""
import json
from . import apireg, erklaeren, haltung, module, passung, planer, trace, verfassung, wachstum, werkstatt
GRIFFE = [("1", "Auftrag", "freier Text, die App plant selbst"),
          ("2", "Ablaeufe", "sechs fertige Arbeitsgaenge"),
          ("3", "Werkstatt", "was geladen, was an, was wartet"),
          ("4", "Spur", "jeder Schritt, jedes Modell, jeder Cent"),
          ("5", "Lehre", "Begriff erklaeren, in drei Stufen"),
          ("6", "Haltung", "Verhaltensprofil, roh nur auf Wunsch")]
def kopf(db, v):
    return (f"KOORDINAT 2.1  Puls {v.puls()} {v.modus()}  Ampel {apireg.ampel(db)}  "
            f"STOP {'AN' if verfassung.stop_gesetzt() else 'aus'}")
def start(db, v):
    while True:
        print("\n" + kopf(db, v))
        for k, t, x in GRIFFE:
            print(f" {k}  {t:<12} {x}")
        print(" q  zurueck\n " + "-" * 56)
        print(" " + trace.zeige(db, None, 6).replace("\n", "\n "))
        try:
            w = input("\n> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return
        if w in ("q", ""):
            return
        try:
            if w == "1":
                auftrag = input("Auftrag: ").strip()
                if not auftrag:
                    continue
                p = planer.plan(auftrag)
                print(f"\nPlan aus {p['quelle']}: {p['ablauf']['titel']}")
                for i, s in enumerate(p["ablauf"]["schritte"], 1):
                    print(f" {i}. {s['titel']}  [{s['art']}] {s.get('erklaerung', '')}")
                if input("\nStart? j/n ").strip().lower() == "j":
                    print(werkstatt.starte(db, v, p)[1])
            elif w == "2":
                for a in planer.vorlagen():
                    print(f" {a['id']:<12} {a['titel']}")
                k = next((x for x in planer.vorlagen() if x["id"] == input("Ablauf: ").strip()), None)
                if k:
                    print(werkstatt.starte(db, v, dict(quelle="vorlage", passung=9, ablauf=k))[1])
            elif w == "3":
                for m in module.liste(db, v):
                    print(f" {'AN ' if m['an'] else 'aus'} {m['name']:<34} {m['lizenz'] or 'KEINE'}")
                print(f"\n {len(wachstum.vorschlaege(db))} Vorschlaege warten.")
                b = input("an/aus <name> | aktiviere <typ> | wachse | vorschlaege\n> ").split()
                if b and b[0] in ("an", "aus") and len(b) > 1:
                    print(module.schalte(db, v, b[1], b[0] == "an")[1])
                elif b and b[0] == "aktiviere" and len(b) > 1:
                    print(passung.aktiviere_fuer(db, v, " ".join(b[1:]))[1])
                elif b and b[0] == "wachse":
                    r = wachstum.zyklus(db, v)
                    print(json.dumps({k: r[k] for k in ("status", "geladen", "eingeschaltet", "entdeckt")},
                                     ensure_ascii=False, indent=1))
                elif b and b[0] == "vorschlaege":
                    for x in wachstum.vorschlaege(db):
                        print(f" {x['id']:>3} {x['repo']:<34} {x['score']:>3} {x['bedarf'][:28]}")
            elif w == "4":
                print(trace.zeige(db, None, 40))
            elif w == "5":
                b = input("Begriff: ").strip()
                if b:
                    print("\n" + erklaeren.erklaere(db, b))
            elif w == "6":
                print("\n".join(haltung.tabelle(True)))
        except (EOFError, KeyboardInterrupt):
            print()
            return
        except Exception as e:
            print(f"Fehler: {type(e).__name__}: {e}")
