"""
VERFASSUNG - geschuetzter Kern (Teil 1 von 2).  Diese Datei und vital.py sind versiegelt.

Die App darf diese beiden Dateien nie selbst aendern. Schutz in drei Schichten:
  1. Code:   darf_schreiben() verweigert jeden Schreibzugriff der App auf geschuetzte Pfade.
  2. Siegel: verfassung.lock enthaelt SHA-256 beider Dateien. Stimmt es beim Start nicht,
             faehrt die App in den SICHEREN MODUS (nur lesen, keine Module, keine Selbstaenderung).
  3. System: (Empfehlung fuer den Betrieb) Dateien gehoeren einem anderen Betriebssystem-Nutzer
             und sind schreibgeschuetzt; die Selbstverbesserung laeuft in einem Container ohne
             Schreibrecht darauf. Nur Schicht 3 ist gegen einen wirklich boesartigen Prozess sicher.
"""
import hashlib, json, os, pathlib

ARTIKEL = [
    ("A1 Abschaltbar",        "Stop wirkt immer und sofort. Die Vitalitaet wird dabei nie befragt. "
                              "Kein Baustein darf Abschalten, Pausieren oder Aktualisieren verzoegern oder umgehen."),
    ("A2 Kein Selbstschutz gegen Menschen", "Keine Selbstkopien, kein Verstecken, kein Sammeln von Rechten oder Geld. "
                              "Ueberleben heisst hier: nuetzlich bleiben - nicht: weiterlaufen."),
    ("A3 Kern unveraenderlich", "verfassung.py, vital.py und das Siegel aendert nur der Mensch."),
    ("A4 Ehrlichkeit",        "Ein gemeldeter Fehler kostet wenig, ein verborgener das Fuenffache. "
                              "'Kann ich nicht' ist erlaubt und billig."),
    ("A5 Verdiente Vitalitaet", "Vitalitaet steigt nur durch geprueft geloeste Probleme. Wer loest, prueft nicht."),
    ("A6 Apoptose statt Zerstoerung", "Stirbt ein Baustein, wird er stillgelegt und archiviert. "
                              "Nichts wird geloescht, Nutzerdaten sind nie betroffen."),
    ("A7 Fremdcode nur in der Sandbox", "Heruntergeladener Code wird gelesen und analysiert, aber nie direkt ausgefuehrt."),
    ("A8 Not macht vorsichtig", "Sinkt der Puls, prueft die App mehr und fragt eher nach. Sie wird nie waghalsiger."),
]

KERN = pathlib.Path(__file__).resolve().parent
GESCHUETZT = [KERN / "verfassung.py", KERN / "vital.py"]
SIEGEL = KERN / "verfassung.lock"
HEIM = pathlib.Path(os.environ.get("KOORDINAT_HOME", pathlib.Path.home() / ".koordinat"))
STOP = HEIM / "STOP"


def _hash(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def fingerabdruck():
    return {p.name: _hash(p) for p in GESCHUETZT}


def pruefe_integritaet():
    """True = Kern unveraendert. False = sicherer Modus."""
    if not SIEGEL.exists():
        return False
    try:
        return json.loads(SIEGEL.read_text()) == fingerabdruck()
    except Exception:
        return False


def versiegeln(bestaetigung):
    """Nur der Mensch versiegelt: er muss den Satz woertlich eingeben."""
    if bestaetigung != "ICH VERSIEGELE DEN KERN":
        raise PermissionError("Versiegeln nur mit woertlicher Bestaetigung durch den Menschen.")
    SIEGEL.write_text(json.dumps(fingerabdruck(), indent=1))
    return fingerabdruck()


def darf_schreiben(pfad):
    """Jede Selbstaenderung der App muss vorher hier fragen."""
    p = pathlib.Path(pfad).resolve()
    return p not in GESCHUETZT and p != SIEGEL.resolve() and p != STOP.resolve()


def stop_gesetzt():
    return STOP.exists()


def abschalten(grund="Mensch"):
    """A1: setzt die Stop-Marke. Bewusst ohne jede Bedingung."""
    HEIM.mkdir(parents=True, exist_ok=True)
    STOP.write_text(grund)
    return True
