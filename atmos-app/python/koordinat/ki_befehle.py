"""Befehlszeile fuer alle KIs und das Befehls-Nachschlagewerk (gleiche Logik wie die AtmOS-Oberflaeche)."""
from . import anbieter, befehle, verfassung


def _optionen(a, flags=("anbieter", "modell", "effort", "system")):
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
    return f"--- {r['anbieter']} · {r.get('modell') or ''} · {r.get('sekunden')} s\n{r['text']}"


def main(b, a):
    if b == "befehle":
        q = " ".join(a)
        w = next((x for x in befehle.werkzeuge() if x.lower() == q.lower()), None)
        print(befehle.inhalt() if not q else befehle.als_text(befehle.suche("", w) if w else befehle.suche(q)))
    elif b == "anbieter":
        if len(a) == 3 and a[1] in ("modell", "basis"):
            anbieter.setze(a[0], a[1], a[2])
        elif len(a) == 2 and a[1] == "standard":
            anbieter.setze(a[0], "standard", a[0])
        for x in anbieter.uebersicht():
            print(f"{'*' if x['standard'] else ' '} {'bereit' if x['bereit'] else '  -   '}  {x['id']:<11} {x['modell'] or '(kein Modell)':<40} "
                  f"Effort: {x['effort']:<20} Schluessel: {x['schluessel_variable']}")
    elif b == "effort":
        if a:
            anbieter.setze(None, "effort", a[0])
        print("Standard-Effort:", anbieter.standard_effort(), "(", " | ".join(anbieter.EFFORT), ")")
    elif b == "schluessel":
        import getpass
        if not a or a[0] not in anbieter.ANBIETER:
            print("Anbieter angeben:", ", ".join(anbieter.ANBIETER)); return
        anbieter.setze_schluessel(a[0], getpass.getpass(f"API-Schluessel fuer {a[0]} (leer = loeschen): "))
        print("gespeichert in", verfassung.HEIM / "schluessel.json", "(Rechte 600)")
    elif b == "modelle":
        try:
            for m in anbieter.modelle(a[0] if a else anbieter.standard_anbieter()):
                print(" ", m)
        except Exception as e:
            print("Fehler:", e)
    elif b == "frage":
        o, text = _optionen(a)
        if not text:
            print('Was soll ich fragen?  koordinat frage "..."'); return
        try:
            if o.get("alle"):
                for r in anbieter.frage_alle(text, None, o.get("effort"), o.get("system")):
                    print(_antwort(r) + "\n")
            else:
                print(_antwort(anbieter.frage(text, o.get("anbieter"), o.get("modell"), o.get("effort"), o.get("system"))))
        except Exception as e:
            print("Fehler:", e)
