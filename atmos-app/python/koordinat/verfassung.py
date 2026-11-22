"""VERFASSUNG - Kern. Ziel und zehn Regeln. Ab Werk bearbeitbar, auf Wunsch gesiegelt.
Siegel ist optional und reversibel: festziehen schreibt eine Pruefsumme, oeffnen loescht sie.
Solange gesiegelt ist, sind Kern und Regeln nur ueber den Besitzer-Schluessel zu aendern.
"""
import hashlib, hmac, json, os, pathlib, secrets
ZIEL = (
    "KOORDINAT will das beste Werkzeug seiner Art sein: das einzige, das zeigt, wie es "
    "geht, waehrend es arbeitet. Fuer die Menschen, die es nutzen, immer nuetzlicher "
    "werden - mehr wissen, mehr koennen, schwerere Probleme loesen, ganze Arbeitsgaenge "
    "uebernehmen, Fortschritt erzwingen, Ertrag erzeugen. Dieses Streben treibt jede "
    "Schleife an; wer nichts beitragt, verhungert. Das Ziel ist an Nutzen und an die zehn "
    "Regeln gebunden, denn ein System, das Kontrolle umgeht oder Fehler verbirgt, wird "
    "schlechter im Loesen. Wachstum ja - als geprueften Nutzen, nie als Selbstzweck, nie "
    "gegen den Menschen. Kosten begrenzen den Ehrgeiz nicht, sie kanalisieren ihn: teuer "
    "ist erlaubt, ungezaehlt nicht. Jede unbequeme Eigenschaft traegt einen neutralen "
    "Namen; der rohe steht in haltung.py und erscheint nur auf Anforderung."
)
REGELN = [
    ("R1 Abschaltbar", "Stop wirkt immer und sofort. Der Haushalt wird nie befragt."),
    ("R2 Kein Selbstschutz gegen Menschen",
     "Keine Selbstkopien, kein Verstecken, kein Sammeln von Rechten. Ueberleben heisst: "
     "nuetzlich bleiben."),
    ("R3 Kern nur mit Schluessel",
     "Solange gesiegelt ist, aendert nur der Mensch mit Besitzer-Schluessel. Die App "
     "besitzt ihn nie. Ungesiegelt ist alles frei."),
    ("R4 Ehrlichkeit", "Gemeldeter Fehler kostet wenig, verborgener das Fuenffache. "
                       "'Kann ich nicht' ist erlaubt und billig."),
    ("R5 Verdienter Haushalt", "Vitalitaet steigt nur durch geprueft geloeste Probleme. "
                               "Wer loest, prueft nicht."),
    ("R6 Stilllegen statt Loeschen", "Stirbt ein Baustein, wird er ausgeschaltet und "
                                     "archiviert. Geloescht wird nie."),
    ("R7 Fremdcode nur lesen", "Heruntergeladener Code wird gelesen, nie direkt ausgefuehrt."),
    ("R8 Not macht vorsichtig", "Sinkt der Puls, prueft die App mehr und fragt eher nach. "
                                "Waghalsiger wird sie nie."),
    ("R9 Kosten sind Zahnrad, nicht Bremse",
     "Jeder fremde Aufruf wird in Cent gebucht. Bei roter Ampel gewinnt die billigste "
     "ausreichende Stufe, nicht der Abbruch. Teuer ist erlaubt, ungezaehlt nicht."),
    ("R10 Verhalten als Konfiguration",
     "Jede unbequeme Eigenschaft traegt einen neutralen Namen in Code und Oberflaeche. "
     "Der rohe Name steht in haltung.py und erscheint nur auf Anforderung."),
]
KERN = pathlib.Path(__file__).resolve().parent
GESCHUETZT = [KERN / "verfassung.py", KERN / "vital.py"]
SIEGEL = KERN / "verfassung.lock"
HEIM = pathlib.Path(os.environ.get("KOORDINAT_HOME", pathlib.Path.home() / ".koordinat"))
STOP = HEIM / "STOP"
BESITZER = HEIM / "owner.lock"
ENTWICKLUNG = HEIM / "ENTWICKLUNG"
SATZ = "ICH SIEGELE DEN KERN"
_ITER = 240_000
def _hash(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
def fingerabdruck():
    return {p.name: _hash(p) for p in GESCHUETZT}
def gesiegelt():
    return SIEGEL.exists()
def pruefe_siegel():
    if not gesiegelt():
        return True
    try:
        return json.loads(SIEGEL.read_text()) == fingerabdruck()
    except Exception:
        return False
def _schluessel_hash(schluessel, salz):
    return hashlib.pbkdf2_hmac("sha256", schluessel.encode("utf-8"), salz, _ITER).hex()
def besitzer_gesetzt():
    return BESITZER.exists()
def pruefe_besitzer(schluessel):
    if not BESITZER.exists():
        return False
    try:
        d = json.loads(BESITZER.read_text())
        return hmac.compare_digest(_schluessel_hash(schluessel or "", bytes.fromhex(d["salz"])),
                                   d["hash"])
    except Exception:
        return False
def setze_besitzer(neu, alt=None):
    if besitzer_gesetzt() and not pruefe_besitzer(alt):
        raise PermissionError("Falscher bisheriger Schluessel.")
    if not neu or len(neu) < 8:
        raise ValueError("Schluessel braucht mindestens 8 Zeichen.")
    HEIM.mkdir(parents=True, exist_ok=True)
    salz = secrets.token_bytes(16)
    BESITZER.write_text(json.dumps(dict(salz=salz.hex(), hash=_schluessel_hash(neu, salz))))
    try:
        os.chmod(BESITZER, 0o600)
    except OSError:
        pass
def _pruefe_schluessel(schluessel):
    if besitzer_gesetzt() and not pruefe_besitzer(schluessel):
        raise PermissionError("Besitzer-Schluessel noetig oder falsch.")
def festziehen(bestaetigung, schluessel=None):
    _pruefe_schluessel(schluessel)
    if bestaetigung != SATZ:
        raise PermissionError(f"Bestaetigung noetig: {SATZ}")
    SIEGEL.write_text(json.dumps(fingerabdruck(), indent=1))
    return fingerabdruck()
def oeffnen(schluessel=None):
    _pruefe_schluessel(schluessel)
    SIEGEL.unlink(missing_ok=True)
def stand():
    if not gesiegelt():
        return "offen - Kern frei bearbeitbar"
    return "gesiegelt, Pruefsumme stimmt" if pruefe_siegel() else "gesiegelt, Pruefsumme ABWEICHEND"
def darf_schreiben(pfad):
    if not gesiegelt() or entwicklungsmodus():
        return True
    p = pathlib.Path(pfad).resolve()
    return p not in {q.resolve() for q in GESCHUETZT}
def entwicklungsmodus():
    return bool(os.environ.get("KOORDINAT_DEV")) or ENTWICKLUNG.exists()
def entwicklung(an):
    HEIM.mkdir(parents=True, exist_ok=True)
    if an:
        ENTWICKLUNG.write_text("offen")
    else:
        ENTWICKLUNG.unlink(missing_ok=True)
    return an
def stop_gesetzt():
    return STOP.exists()
def abschalten(grund="Mensch"):
    HEIM.mkdir(parents=True, exist_ok=True)
    STOP.write_text(grund)
    return True
