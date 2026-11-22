"""Befehlszeile:  python3 -m koordinat <befehl>"""
import json, pathlib, sys
from . import (algorithmen, anbieter, befehle, evolution, github, guide, leitfaden, module, speicher, verfassung,
               vital as vitalmod, wachstum, __version__)

HILFE = f"""KOORDINAT v{__version__} - alle KIs, alle Werkzeuge, alle Befehle an einem Ort

  ALLES AUF EINEN BLICK
  uebersicht                  Stand von allem: KIs, Module, Vorschlaege, Puls
  ui [port]                   Oberflaeche im Browser (Chat, Katalog, Befehle, Ablaeufe, Guide, System)

  ALLE KIs VERBINDEN
  anbieter                    alle KI-Anbieter (Claude, OpenAI, Gemini, Mistral, DeepSeek, xAI, Groq,
                              OpenRouter, Together, Perplexity, Fireworks, Cerebras, Ollama, LM Studio, eigener)
  anbieter <id> modell <name> | basis <url> | standard    Anbieter einstellen
  effort <stufe>              Standard-Effort: aus | low | medium | high | xhigh | max
  schluessel <anbieter>       API-Schluessel sicher speichern (leer lassen = loeschen)
  modelle <anbieter>          aktuelle Modellliste direkt beim Anbieter
  frage "<text>" [--anbieter id] [--modell name] [--effort stufe] [--system "..."] [--alle]
  chat [--anbieter id] [--effort stufe]   Gespraech im Terminal (/effort /modell /anbieter /neu /ende)

  NACHSCHLAGEN
  befehle [werkzeug|suchwort] Befehle und Regler: Claude Code, Codex, Gemini CLI, Aider, Cursor, Ollama,
                              llama.cpp, APIs, MCP, Git/GitHub, Prompting, Effort ueberall

  REPOS UND MODULE
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
  entwicklung [an|aus]        offener Entwurfsmodus: nichts festgezurrt, Kern frei aenderbar
  verfassung                  die 8 Artikel
  versiegeln                  Kern-Siegel setzen (nur Mensch)
  stop | fortsetzen           alles anhalten / Stop-Marke entfernen
  mcp                         als MCP-Server starten (fuer Claude, Cursor ...)"""


def _optionen(a, flags=("anbieter", "modell", "effort", "system")):
    """Trennt --schalter wert von freiem Text."""
    o, rest, i = {}, [], 0
    while i < len(a):
        if a[i] == "--alle":
            o["alle"] = True
        elif a[i].startswith("--") and a[i][2:] in flags and i + 1 < len(a):
            o[a[i][2:]] = a[i + 1]; i += 1
        else:
            rest.append(a[i])
        i += 1
    return o, " ".join(rest)


def _antwort(r):
    if r.get("fehler"):
        return f"--- {r['anbieter']}: FEHLER {r['fehler']}"
    v = r.get("verbrauch") or {}
    toks = v.get("output_tokens") or v.get("completion_tokens") or v.get("candidatesTokenCount")
    return f"--- {r['anbieter']} · {r.get('modell') or ''} · {r.get('sekunden')} s" + (f" · {toks} Tokens" if toks else "") + f"\n{r['text']}"


def chat(o):
    an, mod, eff = o.get("anbieter") or anbieter.standard_anbieter(), o.get("modell"), o.get("effort") or anbieter.standard_effort()
    verlauf = []
    print(f"Chat mit {an} (Effort {eff}). Befehle: /effort <stufe>  /modell <name>  /anbieter <id>  /neu  /ende")
    while True:
        try:
            z = input("du> ").strip()
        except (EOFError, KeyboardInterrupt):
            print(); return
        if not z:
            continue
        if z.startswith("/"):
            k, _, w = z[1:].partition(" ")
            if k in ("ende", "exit", "quit", "bye"): return
            if k == "neu": verlauf = []; print("neues Gespraech.")
            elif k == "effort" and w in anbieter.EFFORT: eff = w; print("Effort", eff)
            elif k == "modell": mod = w or None; print("Modell", mod or "Standard")
            elif k == "anbieter" and w in anbieter.ANBIETER: an, mod, verlauf = w, None, []; print("Anbieter", an, "(neues Gespraech)")
            else: print("unbekannt. /effort " + "|".join(anbieter.EFFORT) + "  /modell <name>  /anbieter <id>  /neu  /ende")
            continue
        try:
            r = anbieter.frage(z, an, mod, eff, o.get("system"), verlauf)
        except Exception as e:
            print("Fehler:", e); continue
        verlauf += [dict(role="user", content=z), dict(role="assistant", content=r["text"])]
        print(_antwort(r))


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
        print("ZIEL\n  " + verfassung.ZIEL + "\n")
        for t, x in verfassung.ARTIKEL: print(f"{t}\n   {x}")
        return
    if b == "entwicklung":
        if a and a[0] in ("an", "aus"):
            verfassung.entwicklung(a[0] == "an")
        print("Entwurfsmodus:", "AN - nichts ist festgezurrt, der Kern ist frei aenderbar."
              if verfassung.entwicklungsmodus() else
              "aus - der Kern ist festgeschnuert (Siegel gilt). 'entwicklung an' oeffnet ihn wieder.")
        print("  (A1 Stop und A2 'App schreibt ihren Kern nie' gelten in beiden Faellen.)")
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
    if b == "befehle":
        q = " ".join(a)
        w = next((x for x in befehle.werkzeuge() if x.lower() == q.lower()), None)
        print(befehle.inhalt() if not q else befehle.als_text(befehle.suche("", w) if w else befehle.suche(q)))
        return
    if b == "anbieter":
        if len(a) >= 2 and a[1] in ("modell", "basis") and len(a) == 3:
            anbieter.setze(a[0], a[1], a[2]); print(f"{a[0]}: {a[1]} = {a[2]}")
        elif len(a) == 2 and a[1] == "standard":
            anbieter.setze(a[0], "standard", a[0]); print(f"Standard-Anbieter: {a[0]}")
        for x in anbieter.uebersicht():
            print(f"{'*' if x['standard'] else ' '} {'bereit' if x['bereit'] else '  -   '}  {x['id']:<11} {x['name']:<34} "
                  f"{x['modell'] or '(kein Modell)':<40} Effort: {x['effort']:<20} Schluessel: {x['schluessel_variable']}")
        print("\n* = Standard. Schluessel: 'koordinat schluessel <id>' oder Umgebungsvariable. Standard-Effort:", anbieter.standard_effort())
        return
    if b == "effort":
        if a:
            anbieter.setze(None, "effort", a[0])
        print("Standard-Effort:", anbieter.standard_effort(), " (Stufen:", " | ".join(anbieter.EFFORT) + ")")
        return
    if b == "schluessel":
        import getpass
        if not a or a[0] not in anbieter.ANBIETER:
            print("Anbieter angeben:", ", ".join(anbieter.ANBIETER)); return
        anbieter.setze_schluessel(a[0], getpass.getpass(f"API-Schluessel fuer {a[0]} (Eingabe bleibt unsichtbar, leer = loeschen): "))
        print("gespeichert in", verfassung.HEIM / "schluessel.json", "(nur fuer dich lesbar)"); return
    if b == "modelle":
        try:
            for m in anbieter.modelle(a[0] if a else anbieter.standard_anbieter()): print(" ", m)
        except Exception as e:
            print("Fehler:", e)
        return
    if b == "ui":
        from . import oberflaeche; oberflaeche.starte(int(a[0]) if a else 8765); return
    if verfassung.stop_gesetzt():
        print("STOP ist gesetzt. Mit 'fortsetzen' aufheben."); return
    if b in ("frage", "chat"):
        o, text = _optionen(a)
        if b == "chat":
            chat(o); return
        if not text:
            print('Was soll ich fragen?  koordinat frage "..."'); return
        try:
            if o.get("alle"):
                for r in anbieter.frage_alle(text, None, o.get("effort"), o.get("system")) or [dict(anbieter="-", fehler="keine KI mit Schluessel bereit")]:
                    print(_antwort(r) + "\n")
            else:
                print(_antwort(anbieter.frage(text, o.get("anbieter"), o.get("modell"), o.get("effort"), o.get("system"))))
        except Exception as e:
            print("Fehler:", e)
        return
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
        print(f"Puls {v.puls()}  Modus {v.modus()}  Kern intakt: {verfassung.pruefe_integritaet()}  "
              f"Entwurfsmodus: {verfassung.entwicklungsmodus()}  Protokoll intakt: {v.kette_intakt()}")
        print("In Not:", v.not_liste() or "-"); print("Stillgelegt:", v.tote() or "-"); print("Hunger:", v.hunger() or "-")
    elif b == "katalog":
        for e in kat:
            if not a or e["kategorie"].lower().startswith(" ".join(a).lower()):
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
    elif b == "uebersicht":
        from . import oberflaeche
        u = oberflaeche._uebersicht(db, v)
        print(f"KOORDINAT v{u['version']}   Puls {u['puls']}  Modus {u['modus']}  Kern intakt: {u['kern_intakt']}"
              + ("  STOP!" if u["stop"] else ""))
        print(f"  KIs bereit      {sum(x['bereit'] for x in u['anbieter'])} von {len(u['anbieter'])}: "
              + ", ".join(x["id"] for x in u["anbieter"] if x["bereit"]) + f"   (Standard-Effort {u['effort']})")
        print(f"  Katalog         {u['katalog']} gepruefte Repos      (koordinat katalog)")
        print(f"  Module          {u['module_an']} an von {u['module']}         (koordinat liste)")
        print(f"  Vorschlaege     {u['vorschlaege']} offen               (koordinat vorschlaege)")
        print(f"  Befehle         {u['befehle']} Eintraege           (koordinat befehle)")
        print(f"  Ablaeufe        {u['ablaeufe']} gefuehrt             (koordinat leitfaden)")
        print(f"  Guide           {u['guide']} Begriffe             (koordinat guide)")
        print("  Oberflaeche     koordinat ui")
    else:
        print(HILFE)


if __name__ == "__main__":
    main(sys.argv[1:])
