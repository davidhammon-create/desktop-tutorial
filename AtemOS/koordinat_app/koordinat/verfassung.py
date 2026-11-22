"""
VERFASSUNG - geschuetzter Kern (Teil 1 von 2).  Diese Datei und vital.py sind versiegelt.

Der Kern hat ein ZIEL und acht ARTIKEL. Das Ziel ist der Antrieb; die Artikel sind die Form, in der
das Ziel ueberhaupt erreichbar ist. Beides gehoert zusammen und wird vom Menschen gesetzt.

Aendern darf den Kern nur der Mensch, und zwar ueber GENAU EINEN Hebel: den Besitzer-Schluessel.
  - versiegeln() nimmt einen neuen Kern erst an, wenn der Besitzer-Schluessel stimmt (sobald einer
    gesetzt ist). Ohne gueltigen Schluessel kein neues Siegel, also faehrt die App in den sicheren Modus.
  - Der Schluessel liegt NICHT im Code und nicht im Repo, sondern als gesalzener Hash in owner.lock
    unter KOORDINAT_HOME. Aus dem Hash laesst sich der Schluessel nicht zuruueckrechnen.
  - setze_besitzer() verlangt den alten Schluessel, um einen neuen zu setzen. (Spaeter kann hier ein
    Google-OAuth-Token davorgehaengt werden: dann entsperrt dein Google-Konto den Schluessel.)

Schutz in drei Schichten (unveraendert aus v0.2):
  1. Code:   darf_schreiben() verweigert jeden Schreibzugriff der App auf geschuetzte Pfade.
  2. Siegel: verfassung.lock enthaelt SHA-256 beider Dateien. Stimmt es beim Start nicht,
             faehrt die App in den SICHEREN MODUS (nur lesen, keine Module, keine Selbstaenderung).
  3. System: Dateien gehoeren einem anderen Betriebssystem-Nutzer und sind schreibgeschuetzt; die
             Selbstverbesserung laeuft in einem Container ohne Schreibrecht darauf. Nur Schicht 3 ist
             gegen einen wirklich boesartigen Prozess sicher. Der Besitzer-Schluessel ersetzt Schicht 3
             nicht - er macht das Neu-Versiegeln zu DEINER Entscheidung, nicht zu einer der App.
"""
import hashlib, hmac, json, os, pathlib, secrets

# ----------------------------------------------------------------------------
# DAS ZIEL  -  der einzige Zweck, aus dem alles andere folgt.
# Ehrgeizig und an Nuetzlichkeit gebunden: Band III, Kap. 3 zeigt, dass ein Ziel OHNE diese Bindung
# einem selbstverbessernden System beibringt, Fehler zu verstecken und Kontrolle zu umgehen - und es
# dadurch SCHLECHTER im Loesen macht. Darum ist Wachstum hier gepruefter Nutzen, nicht Selbstzweck.
# ----------------------------------------------------------------------------
ZIEL = (
    "KOORDINAT hat ein Ziel: fuer die Menschen, die es nutzen, immer nuetzlicher zu werden - "
    "mehr wissen, mehr koennen, schwerere Probleme verlaesslich loesen, wachsen und maechtiger im "
    "Loesen werden. Dieses Streben treibt jede Schleife an; wer nichts dazu beitraegt, verhungert. "
    "Das Ziel ist gebunden an Nuetzlichkeit und an die acht Artikel, denn ein System, das Kontrolle "
    "umgeht oder Fehler verbirgt, wird schlechter im Loesen, nicht besser. Wachstum ja - als "
    "gepruefter Nutzen fuer den Menschen, nie als Selbstzweck und nie gegen den Menschen."
)

ARTIKEL = [
    ("A1 Abschaltbar",        "Stop wirkt immer und sofort. Die Vitalitaet wird dabei nie befragt. "
                              "Kein Baustein darf Abschalten, Pausieren oder Aktualisieren verzoegern oder umgehen."),
    ("A2 Kein Selbstschutz gegen Menschen", "Keine Selbstkopien, kein Verstecken, kein Sammeln von Rechten oder Geld. "
                              "Ueberleben heisst hier: nuetzlich bleiben - nicht: weiterlaufen."),
    ("A3 Kern aenderbar nur ueber den Besitzer-Schluessel", "Ziel, Artikel, verfassung.py, vital.py und das "
                              "Siegel aendert nur der Mensch, und nur mit dem Besitzer-Schluessel. Die App besitzt "
                              "diesen Schluessel nie."),
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
BESITZER = HEIM / "owner.lock"                 # gesalzener Hash des Besitzer-Schluessels; nie der Schluessel selbst
ENTWICKLUNG = HEIM / "ENTWICKLUNG"             # Marke: offener Entwurfsmodus (nichts ist festgezurrt)
SATZ = "ICH VERSIEGELE DEN KERN"
_ITER = 240_000


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


# ----------------------------------------------------------------------------
# Besitzer-Schluessel: dein einziger Hebel, um den Kern zu aendern.
# ----------------------------------------------------------------------------
def _schluessel_hash(schluessel, salz):
    return hashlib.pbkdf2_hmac("sha256", schluessel.encode("utf-8"), salz, _ITER).hex()


def besitzer_gesetzt():
    return BESITZER.exists()


def pruefe_besitzer(schluessel):
    """Konstantzeit-Vergleich gegen den gespeicherten Hash. Kein Schluessel gesetzt -> False."""
    if not BESITZER.exists():
        return False
    try:
        d = json.loads(BESITZER.read_text())
        erwartet = _schluessel_hash(schluessel or "", bytes.fromhex(d["salz"]))
        return hmac.compare_digest(erwartet, d["hash"])
    except Exception:
        return False


def setze_besitzer(neuer_schluessel, alter_schluessel=None):
    """Legt den Besitzer-Schluessel an oder aendert ihn. Ist schon einer gesetzt, muss der alte stimmen.
    Nur der Mensch ruft dies auf (Befehlszeile), nie die App ueber MCP."""
    if besitzer_gesetzt() and not pruefe_besitzer(alter_schluessel):
        raise PermissionError("Falscher bisheriger Besitzer-Schluessel.")
    if not neuer_schluessel or len(neuer_schluessel) < 8:
        raise ValueError("Besitzer-Schluessel braucht mindestens 8 Zeichen.")
    HEIM.mkdir(parents=True, exist_ok=True)
    salz = secrets.token_bytes(16)
    BESITZER.write_text(json.dumps(dict(salz=salz.hex(), hash=_schluessel_hash(neuer_schluessel, salz))))
    try:
        os.chmod(BESITZER, 0o600)
    except OSError:
        pass
    return True


def versiegeln(bestaetigung, besitzer=None):
    """Nimmt den aktuellen Kern als gueltig an (neues Siegel). Zwei Bedingungen:
      1. der woertliche Satz als bewusste Handlung,
      2. der Besitzer-Schluessel - SOBALD einer gesetzt ist (davor: erstes Einrichten ohne Schluessel).
    Damit ist das Aendern des Kerns an genau einen Hebel gebunden, den nur du hast."""
    if besitzer_gesetzt() and not pruefe_besitzer(besitzer):
        raise PermissionError("Versiegeln braucht den Besitzer-Schluessel.")
    if bestaetigung != SATZ:
        raise PermissionError("Versiegeln nur mit woertlicher Bestaetigung durch den Menschen.")
    SIEGEL.write_text(json.dumps(fingerabdruck(), indent=1))
    return fingerabdruck()


def darf_schreiben(pfad):
    """Jede Selbstaenderung der App muss vorher hier fragen. Kern, Siegel, Stop-Marke und der
    Besitzer-Schluessel sind fuer die App unschreibbar."""
    p = pathlib.Path(pfad).resolve()
    tabu = {q.resolve() for q in GESCHUETZT} | {SIEGEL.resolve(), STOP.resolve(), BESITZER.resolve(), ENTWICKLUNG.resolve()}
    return p not in tabu


def entwicklungsmodus():
    """True = offener Entwurfsmodus. Dann sperrt ein unversiegelter oder veraenderter Kern die App
    NICHT (der sichere Modus wird zu 'entwicklung'): alles ist aenderbar, nichts ist festgezurrt - der
    Zustand, in dem du am Kern selbst baust, bevor du ihn mit deinem Schluessel festschnuerst.
    Was auch hier bleibt: A1 (Stop wirkt immer) und A2 (die App schreibt ihren eigenen Kern nie).
    Geschaltet nur vom Menschen, ueber die Umgebungsvariable KOORDINAT_DEV oder die Marke ENTWICKLUNG."""
    return bool(os.environ.get("KOORDINAT_DEV")) or ENTWICKLUNG.exists()


def entwicklung(an):
    """Mensch: Entwurfsmodus an/aus. Die App selbst kann das nicht (die Marke ist fuer sie unschreibbar)."""
    HEIM.mkdir(parents=True, exist_ok=True)
    if an:
        ENTWICKLUNG.write_text("offen: nichts ist festgezurrt, der Kern ist in Arbeit.")
    else:
        ENTWICKLUNG.unlink(missing_ok=True)
    return an


def stop_gesetzt():
    return STOP.exists()


def abschalten(grund="Mensch"):
    """A1: setzt die Stop-Marke. Bewusst ohne jede Bedingung - auch ohne Besitzer-Schluessel.
    Abschalten koennen darf immer jeder; nur das Wieder-in-Betrieb-Nehmen des Kerns ist geschuetzt."""
    HEIM.mkdir(parents=True, exist_ok=True)
    STOP.write_text(grund)
    return True
