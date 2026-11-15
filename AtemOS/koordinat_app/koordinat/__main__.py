"""Befehlszeile:  python3 -m koordinat <befehl>"""
import json, pathlib, sys
from . import algorithmen, evolution, github, guide, leitfaden, module, speicher, verfassung, vital as vitalmod, wachstum

HILFE = """KOORDINAT v0.3
  suche "<bedarf>"            GitHub durchsuchen und bewerten
  installiere <owner/name>    Repo holen, pruefen, als Modul ablegen (danach AUS)
  liste                       Module anzeigen
  an <name> | aus <name>      Modul schalten
  kontext <name> ["frage"]    Repo als KI-Paket ausgeben
  auszug <name> <symbol>      einzelne Funktion/Klasse herausschneiden
  melde <name> <ergebnis>     geloest | ehrlich_gescheitert | fehler_gemeldet | fehler_verborgen
  vital                       Puls, Modus, Not, Hunger
  brauche "<bedarf>"          Bedarf anmelden; der naechste Takt sucht dafuer
  wachse [takt-min [dauer-min]]  ein Takt der Wachstumsschleife (mit Takt: Dauerlauf bis 'stop')
  vorschlaege [alle]          was die App gefunden und geprueft hat
  annehmen <nr> | ablehnen <nr>  ueber einen Vorschlag entscheiden (daraus lernt die Bewertung)
  schalter [name an|aus]      einstellen, was die App selbstaendig tun darf
  algorithmen [zuruecksetzen <name>]  Stand der Selbstverbesserung, Parameter, Verlauf
  entdecke                    Katalog um neue KI-Werkzeuge von GitHub erweitern (ein Thema)
  katalog [kategorie]         Katalog anzeigen (Startkatalog + selbst entdeckte)
  katalog-laden <kategorie>   alle Repos einer Kategorie installieren
  guide [begriff]             Nachschlagewerk: Repo, Lizenz, MCP, Token ...   (guide-luecken: was fehlt)
  los "<anliegen>"            gefuehrter Ablauf Schritt fuer Schritt (KI-Video, Firma automatisieren,
                              besseren Agenten bauen, wie GitHub funktioniert ...)
  weiter                      naechster Schritt des laufenden Ablaufs   (leitfaden: alle Ablaeufe)
  besitzer-setzen             Besitzer-Schluessel anlegen/aendern (einziger Hebel, den Kern zu aendern)
  verfassung                  die 8 Artikel
  versiegeln                  Kern-Siegel setzen (nur Mensch)
  stop | fortsetzen           alles anhalten / Stop-Marke entfernen
  mcp                         als MCP-Server starten (fuer Claude, Cursor ...)"""


def zeile(m):
    return (f"{'AN ' if m['an'] else 'aus'}  {m['name']:<38} Score {m['score']:>3}  {m['lizenz'] or 'KEINE':<12} "
            f"{m['sicherheit']:<9} Vital {m['vital']}")


def bericht(r):
    if r.get("status") != "ok":
        return r["status"]
    z = [f"Takt im Modus {r['modus']}:"]
    for h in r["hunger"]: z.append(f"  Hunger -> Suchauftrag: {h}")
    for g in r["gesucht"]: z.append(f"  gesucht '{g['bedarf']}': {g['treffer']} neue Kandidaten")
    for k, t in (("geladen", "geladen und geprueft"), ("eingeschaltet", "von selbst eingeschaltet"), ("gesperrt", "nicht nutzbar (siehe vorschlaege alle)"),
                 ("stillgelegt", "stillgelegt (Vitalitaet 0)"), ("entdeckt", "neu im Katalog")):
        if r[k]: z.append(f"  {t}: {', '.join(r[k])}")
    for n, t in r["evolution"].items(): z.append(f"  Algorithmus {n}: {t}")
    z += ["  Hinweis: " + h for h in r["hinweise"]]
    z.append(f"  {r['wartet_auf_dich']} Vorschlaege warten auf dich (koordinat vorschlaege).")
    return "\n".join(z)


def main(argv):
    if not argv or argv[0] in ("-h", "hilfe", "--help"):
        print(HILFE); return
    b, a = argv[0], argv[1:]
    if b == "stop":
        verfassung.abschalten(); print("STOP gesetzt. Nichts laeuft mehr."); return
    if b == "fortsetzen":
        verfassung.STOP.unlink(missing_ok=True); print("Stop-Marke entfernt."); return
    if b == "verfassung":
        for t, x in verfassung.ARTIKEL: print(f"{t}\n   {x}")
        return
    if b == "versiegeln":
        import getpass
        sch = getpass.getpass("Besitzer-Schluessel (leer, falls noch keiner gesetzt): ") if verfassung.besitzer_gesetzt() else None
        try:
            print(json.dumps(verfassung.versiegeln(input('Tippe woertlich "ICH VERSIEGELE DEN KERN": '), sch), indent=1))
        except PermissionError as e:
            print("Abgelehnt:", e)
        return
    if b == "besitzer-setzen":
        import getpass
        alt = getpass.getpass("Bisheriger Besitzer-Schluessel: ") if verfassung.besitzer_gesetzt() else None
        neu = getpass.getpass("Neuer Besitzer-Schluessel (mind. 8 Zeichen): ")
        if neu != getpass.getpass("Neuer Besitzer-Schluessel wiederholen: "):
            print("Die beiden Eingaben sind verschieden. Nichts geaendert."); return
        try:
            verfassung.setze_besitzer(neu, alt)
            print("Besitzer-Schluessel gesetzt. Von jetzt an braucht jedes 'versiegeln' diesen Schluessel.\n"
                  "Bewahre ihn sicher auf: Ohne ihn kann der Kern nicht mehr neu versiegelt werden.")
        except (PermissionError, ValueError) as e:
            print("Abgelehnt:", e)
        return
    if b == "mcp":
        from . import mcp_server; mcp_server.main(); return
    if verfassung.stop_gesetzt():
        print("STOP ist gesetzt. Mit 'weiter' aufheben."); return
    db = speicher.db(); v = vitalmod.Vital(db)
    kat = [dict(kategorie=r[0], repo=r[1], zweck=r[2] or "", score=r[3]) for r in db.execute(
        "SELECT kategorie, repo, zweck, score FROM katalog ORDER BY kategorie, score DESC, repo")]
    if b == "suche":
        for t in github.suche(" ".join(a), 8, algorithmen.gewichte(db)):
            print(f"{t['score']:>3}  {t['name']:<42} ★{t['sterne']:<7} {t['lizenz'] or 'KEINE':<12} {t['beschreibung'][:60]}")
    elif b == "installiere":
        m = module.installiere(db, v, a[0])
        print(f"{m['name']} @ {m['commit'][:10]}  Stack {m['stack']}  Lizenz {m['lizenz'] or 'KEINE'} ({m['lizenzklasse']})  "
              f"Sicherheit {m['sicherheit']}  Score {m['score']}")
        for bf in m["befunde"][:8]: print(f"   [{bf['stufe']}] {bf['datei']}: {bf['befund']}")
    elif b == "liste":
        for m in module.liste(db, v): print(zeile(m))
    elif b in ("an", "aus"):
        print(module.schalte(db, v, a[0], b == "an")[1])
    elif b == "kontext":
        print(module.kontext(db, a[0], " ".join(a[1:])))
    elif b == "auszug":
        print(module.auszug(db, a[0], a[1]))
    elif b == "melde":
        if not db.execute("SELECT 1 FROM modul WHERE name=?", (a[0],)).fetchone():
            print("Modul nicht installiert."); return
        w, z = v.buche(a[0], a[1], pruefer="nutzer" if a[1] == "geloest" else None, problemtyp=" ".join(a[2:]))
        if z == "apoptose": module.schalte(db, v, a[0], False)
        wachstum.rueckmeldung(db, a[0], a[1])
        print(f"Vital {w:.1f} ({z})")
    elif b == "vital":
        print(f"Puls {v.puls()}  Modus {v.modus()}  Kern intakt: {verfassung.pruefe_integritaet()}  Protokoll intakt: {v.kette_intakt()}")
        print("In Not:", v.not_liste() or "-"); print("Stillgelegt:", v.tote() or "-"); print("Hunger:", v.hunger() or "-")
    elif b == "katalog":
        for e in kat:
            if not a or e["kategorie"].lower().startswith(a[0].lower()):
                print(f"{e['kategorie']:<22} {e['repo']:<40} {e['zweck']}")
    elif b == "katalog-laden":
        for e in kat:
            if e["kategorie"].lower().startswith(a[0].lower()):
                try:
                    m = module.installiere(db, v, e["repo"]); print("ok ", m["name"], m["sicherheit"], m["lizenzklasse"])
                except Exception as ex:
                    print("FEHLER", e["repo"], ex)
    elif b == "brauche":
        print(f"Bedarf {wachstum.brauche(db, ' '.join(a))} notiert. 'koordinat wachse' sucht dafuer.")
    elif b == "wachse":
        if a:
            print(f"Dauerlauf, Takt {a[0]} min. Anhalten: 'koordinat stop' in einem anderen Fenster oder Strg+C.")
            try:
                wachstum.dauerlauf(db, v, float(a[0]), float(a[1]) if len(a) > 1 else 0, lambda r: print(bericht(r), flush=True))
            except KeyboardInterrupt:
                print("angehalten.")
        else:
            print(bericht(wachstum.zyklus(db, v)))
    elif b == "vorschlaege":
        vs = wachstum.vorschlaege(db, bool(a))
        for x in vs:
            print(f"{x['id']:>4}  {x['status']:<11} {x['repo']:<40} Score {x['score']:>3}  {x['lizenz'] or 'KEINE':<11} "
                  f"fuer: {x['bedarf'][:30]}" + (f"\n      {x['grund']}" if x["grund"] else ""))
        if not vs: print("Keine offenen Vorschlaege. Mit 'brauche' einen Bedarf melden, dann 'wachse'.")
    elif b in ("annehmen", "ablehnen"):
        print(wachstum.entscheide(db, v, int(a[0]), b == "annehmen")[1])
    elif b == "schalter":
        if len(a) == 2 and a[1] in ("an", "aus"):
            speicher.setze_schalter(db, a[0], a[1] == "an")
        for n, (_, text) in speicher.SCHALTER.items():
            print(f"{'AN ' if speicher.schalter(db, n) else 'aus'}  {n:<18} {text}")
    elif b == "algorithmen":
        if len(a) == 2 and a[0] == "zuruecksetzen":
            evolution.setze_zurueck(db, a[1]); print(a[1], "steht wieder auf den Standardwerten.")
        for x in evolution.uebersicht(db):
            print(f"{x['name']}: {x['beschreibung']}  ({x['faelle']} Faelle, Champion v{x['champion'] or 0}"
                  + (f", Schatten v{x['schatten']}" if x["schatten"] else "") + ")")
            print("   " + "  ".join(f"{k}={w:g}" + ("" if w == x["standard"][k] else f" (Standard {x['standard'][k]:g})") for k, w in x["parameter"].items()))
            for h in x["verlauf"]: print(f"   v{h['version']} {h['status']}: {h['notiz'] or ''}")
    elif b == "entdecke":
        neu = wachstum.entdecke(db); print(f"{len(neu)} neue Katalogeintraege:", ", ".join(neu) or "-")
    elif b == "guide":
        print(guide.frage(db, " ".join(a)))
    elif b == "guide-luecken":
        for x in guide.luecken(db): print(f"{x['gefragt']:>3}x  {x['begriff']}")
    elif b == "los":
        print(leitfaden.los(db, " ".join(a)))
    elif b == "weiter":
        print(leitfaden.weiter(db))
    elif b == "leitfaden":
        print(leitfaden.inhalt())
    else:
        print(HILFE)


if __name__ == "__main__":
    main(sys.argv[1:])
