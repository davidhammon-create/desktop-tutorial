#!/usr/bin/env python3
"""
Erzeugt eine PDF mit dem vollständigen Quellcode des Projekts.

    python3 scripts/code2pdf.py          →  Modellsammlung-Quellcode.pdf

Aufbau: Titelseite, Kurzüberblick über die Architektur, Inhaltsverzeichnis mit
Seitenzahlen, danach jede Datei vollständig mit Zeilennummern.

Zwei bewusste Entscheidungen:

1. Gezeichnet wird direkt auf den Canvas statt über Platypus-Flowables. Damit
   liegen Umbruchspalte, Zeilennummern und Seitenaufteilung exakt fest, und der
   Code muss nicht durch den XML-Parser von reportlab – sonst würden Zeichen wie
   < und & im Quelltext zum Problem.

2. Eingebettet wird DejaVu Sans Mono. Die in reportlab eingebauten Schriften
   decken nur Latin-1 ab; der Quelltext enthält aber ψ, ₀, ², Å, µ, → und
   weitere Zeichen, die sonst als schwarze Kästchen erscheinen würden.
"""
from __future__ import annotations

import datetime as dt
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from reportlab.lib.colors import Color, HexColor
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as pdfcanvas

WURZEL = Path(__file__).resolve().parent.parent
ZIEL = WURZEL / "Modellsammlung-Quellcode.pdf"

# --------------------------------------------------------------------- Layout
SEITE_B, SEITE_H = A4
RAND_L, RAND_R = 38, 26
RAND_O, RAND_U = 52, 40

SCHRIFT = "DejaVuSansMono"
SCHRIFT_FETT = "DejaVuSansMono-Bold"
# Ausweichschriften für Zeichen, die die Monospace-Schrift nicht enthält
FALLBACKS = ["FallbackSans", "FallbackMono"]
GROESSE = 6.7
ZEILE = 8.15
NR_BREITE = 24  # Spalte für Zeilennummern

# DejaVu Sans Mono hat eine Zeichenbreite von 0,602 em.
ZEICHENBREITE = GROESSE * 0.602
CODE_X = RAND_L + NR_BREITE
CODE_BREITE = SEITE_B - CODE_X - RAND_R
SPALTEN = int(CODE_BREITE / ZEICHENBREITE)  # Umbruch nach so vielen Zeichen

ZEILEN_PRO_SEITE = int((SEITE_H - RAND_O - RAND_U) / ZEILE)

# ---------------------------------------------------------------------- Farben
C_TEXT = HexColor("#14181f")
C_NR = HexColor("#a8b0bd")
C_KOMMENTAR = HexColor("#5a7d5a")
C_AKZENT = HexColor("#2f5fb3")
C_GRAU = HexColor("#6b7280")
C_LINIE = HexColor("#d7dbe2")
C_KOPF_BG = HexColor("#eef1f6")

# ------------------------------------------------------------- Dateiauswahl
EINSCHLUSS = [
    "package.json",
    "index.html",
    "vite.config.js",
    "electron-builder.yml",
    ".gitignore",
    "README.md",
    "electron/main.cjs",
    "electron/preload.cjs",
    "scripts/smoke.mjs",
    "scripts/electron-dev.mjs",
    "scripts/icons.py",
    "scripts/code2pdf.py",
    "src/main.jsx",
    "src/App.jsx",
    "src/styles.css",
    "src/pwa/PwaLeiste.jsx",
    "src/pwa/register-stub.js",
    "src/three/Viewer.jsx",
    "src/three/lib.js",
    "src/models/index.js",
]
# Alle Modelle nach Fachbereich sortiert anhängen
for fach in ("physik", "chemie", "biologie", "medizin"):
    for datei in sorted((WURZEL / "src" / "models" / fach).glob("*.js")):
        EINSCHLUSS.append(str(datei.relative_to(WURZEL)))

KOMMENTARZEILE = re.compile(r"^\s*(//|#(?!!)|\*|/\*|--|<!--)")


@dataclass
class Eintrag:
    pfad: str
    zeilen: list[str]
    startseite: int = 0
    seiten: int = 0
    hinweis: str = ""
    # Umgebrochene Darstellungszeilen: (nummer|None, text)
    ausgabe: list[tuple[int | None, str]] = field(default_factory=list)


BESCHREIBUNG = {
    "package.json": "Abhängigkeiten und alle npm-Skripte",
    "index.html": "HTML-Grundgerüst, PWA- und iOS-Metadaten",
    "vite.config.js": "Build für zwei Ziele: Web/PWA und Electron",
    "electron-builder.yml": "Installer-Konfiguration für Windows, macOS, Linux",
    ".gitignore": "Vom Repository ausgeschlossene Pfade",
    "README.md": "Projektdokumentation",
    "electron/main.cjs": "Electron-Hauptprozess (Fenster, Menü, Sicherheit)",
    "electron/preload.cjs": "Isolierte Brücke zum Renderer",
    "scripts/smoke.mjs": "Browser-Test über alle Modelle",
    "scripts/electron-dev.mjs": "Startet Vite und Electron gemeinsam",
    "scripts/icons.py": "Erzeugt die App-Icons",
    "scripts/code2pdf.py": "Erzeugt genau diese PDF",
    "src/main.jsx": "Einstiegspunkt von React",
    "src/App.jsx": "Oberfläche: Navigation, Werkzeuge, Infopanel",
    "src/styles.css": "Gesamtes Styling",
    "src/pwa/PwaLeiste.jsx": "Installations-Knopf und Update-Hinweis",
    "src/pwa/register-stub.js": "Ersatzmodul für den Electron-Build",
    "src/three/Viewer.jsx": "Renderer, Kamera, Beschriftungen, Aufräumen",
    "src/three/lib.js": "Geometrie-Bausteine für alle Modelle",
    "src/models/index.js": "Registry und Volltextsuche",
}


# Zeichenvorrat je geladener Schrift: Name -> Menge der Codepoints
ZEICHENVORRAT: dict[str, set[int]] = {}
# Zeichen, für die keine Schrift gefunden wurde (für den Hinweis auf der Titelseite)
UNDARSTELLBAR: set[str] = set()


def _registrieren(name: str, pfad: Path) -> bool:
    if not pfad.exists():
        return False
    pdfmetrics.registerFont(TTFont(name, str(pfad)))
    ZEICHENVORRAT[name] = set(pdfmetrics.getFont(name).face.charToGlyph.keys())
    return True


def schriften_laden() -> None:
    """
    Lädt die Monospace-Schrift und zwei Ausweichschriften.

    Hintergrund: Der Quelltext enthält neben ψ, ₀, ² und Å auch UI-Symbole wie
    ☰, ⏸, ⟲ und ⬡. DejaVu Sans Mono deckt davon nicht alles ab – fehlende
    Zeichen würden als schwarze Kästchen erscheinen und damit Information
    zerstören. Deshalb die Kette Mono → DejaVu Sans → FreeMono.
    """
    ordner = [
        Path("/usr/share/fonts/truetype/dejavu"),
        Path("/usr/share/fonts/TTF"),
        Path("/Library/Fonts"),
    ]
    geladen = False
    for o in ordner:
        if _registrieren(SCHRIFT, o / "DejaVuSansMono.ttf") and _registrieren(
            SCHRIFT_FETT, o / "DejaVuSansMono-Bold.ttf"
        ):
            geladen = True
            break
    if not geladen:
        sys.exit(
            "DejaVu Sans Mono nicht gefunden. Unter Debian/Ubuntu:\n"
            "  apt-get install fonts-dejavu-core"
        )

    for name, kandidaten in (
        ("FallbackSans", ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]),
        ("FallbackMono", ["/usr/share/fonts/truetype/freefont/FreeMono.ttf"]),
    ):
        for k in kandidaten:
            if _registrieren(name, Path(k)):
                break


def schrift_fuer(zeichen: str) -> str | None:
    """Erste Schrift der Kette, die dieses Zeichen darstellen kann."""
    cp = ord(zeichen)
    if cp in ZEICHENVORRAT.get(SCHRIFT, ()):
        return SCHRIFT
    for fb in FALLBACKS:
        if cp in ZEICHENVORRAT.get(fb, ()):
            return fb
    return None


def darstellbar_machen(text: str) -> str:
    """
    Ersetzt Zeichen, die keine der geladenen Schriften kennt (etwa Emoji wie
    🧬 oder 🫀), durch ihre Codepoint-Schreibweise <U+1F9EC>.

    Das geschieht bewusst VOR dem Zeilenumbruch, damit die Spaltenbreite stimmt.
    Ein schwarzes Kästchen würde die Information vernichten; die Codepoint-Form
    bleibt eindeutig rückübersetzbar.
    """
    if all(ord(c) < 128 for c in text):
        return text
    teile = []
    for c in text:
        if ord(c) < 128 or schrift_fuer(c):
            teile.append(c)
        else:
            UNDARSTELLBAR.add(c)
            teile.append(f"<U+{ord(c):04X}>")
    return "".join(teile)


def umbrechen(text: str, breite: int) -> list[str]:
    """Bricht eine zu lange Zeile um und rückt die Fortsetzung passend ein."""
    if len(text) <= breite:
        return [text]

    # Einrückung der Ursprungszeile für die Folgezeilen übernehmen, damit die
    # Struktur des Codes erhalten bleibt.
    einzug = len(text) - len(text.lstrip(" "))
    einzug = min(einzug + 4, max(0, breite - 20))
    teile = [text[:breite]]
    rest = text[breite:]
    fortsetzung = breite - einzug
    while rest:
        teile.append(" " * einzug + rest[:fortsetzung])
        rest = rest[fortsetzung:]
    return teile


def dateien_sammeln() -> list[Eintrag]:
    eintraege: list[Eintrag] = []
    for rel in EINSCHLUSS:
        pfad = WURZEL / rel
        if not pfad.exists():
            print(f"  übersprungen (fehlt): {rel}")
            continue
        zeilen = pfad.read_text(encoding="utf-8").rstrip("\n").split("\n")
        e = Eintrag(pfad=rel, zeilen=zeilen, hinweis=BESCHREIBUNG.get(rel, ""))

        # Modellbeschreibung aus dem Modell selbst ziehen
        if rel.startswith("src/models/") and rel != "src/models/index.js":
            inhalt = "\n".join(zeilen)
            name = re.search(r"^\s*name:\s*'([^']+)'", inhalt, re.M)
            if name:
                e.hinweis = f"Modell: {name.group(1)}"

        for nr, zeile in enumerate(zeilen, start=1):
            # Tabulatoren vereinheitlichen, damit die Spaltenbreite stimmt
            zeile = darstellbar_machen(zeile.replace("\t", "    "))
            for i, teil in enumerate(umbrechen(zeile, SPALTEN)):
                e.ausgabe.append((nr if i == 0 else None, teil))
        eintraege.append(e)
    return eintraege


def codezeile_zeichnen(c: pdfcanvas.Canvas, x: float, y: float, text: str) -> None:
    """
    Zeichnet eine Codezeile und wechselt dabei zeichenweise die Schrift, wenn
    die Monospace-Schrift ein Zeichen nicht kennt.

    Weil die Ausweichschriften andere Zeichenbreiten haben, wird jede Gruppe an
    ihrer exakten Spaltenposition gesetzt – so bleibt das Raster erhalten und
    Einrückungen stimmen weiterhin.
    """
    vorrat = ZEICHENVORRAT.get(SCHRIFT, ())
    # Schnellweg: die weit überwiegende Mehrzahl der Zeilen ist reines Mono
    if all(ord(ch) < 128 or ord(ch) in vorrat for ch in text):
        c.setFont(SCHRIFT, GROESSE)
        c.drawString(x, y, text)
        return

    gruppe: list[str] = []
    gruppen_schrift = SCHRIFT
    gruppen_start = 0

    def gruppe_setzen() -> None:
        if not gruppe:
            return
        c.setFont(gruppen_schrift, GROESSE)
        c.drawString(x + gruppen_start * ZEICHENBREITE, y, "".join(gruppe))

    for i, ch in enumerate(text):
        schrift = SCHRIFT if ord(ch) < 128 else (schrift_fuer(ch) or SCHRIFT)
        if schrift != gruppen_schrift:
            gruppe_setzen()
            gruppe, gruppen_schrift, gruppen_start = [], schrift, i
        gruppe.append(ch)
    gruppe_setzen()


class Setzer:
    """Kapselt Seitenzähler, Kopf- und Fußzeile."""

    def __init__(self, c: pdfcanvas.Canvas):
        self.c = c
        self.seite = 1
        self.y = SEITE_H - RAND_O
        self.aktuelle_datei = ""

    def fusszeile(self) -> None:
        c = self.c
        c.setStrokeColor(C_LINIE)
        c.setLineWidth(0.4)
        c.line(RAND_L, RAND_U - 10, SEITE_B - RAND_R, RAND_U - 10)
        c.setFont(SCHRIFT, 6.4)
        c.setFillColor(C_GRAU)
        c.drawString(RAND_L, RAND_U - 21, "Modellsammlung – Quellcode")
        c.drawRightString(SEITE_B - RAND_R, RAND_U - 21, f"Seite {self.seite}")

    def kopfzeile(self) -> None:
        if not self.aktuelle_datei:
            return
        c = self.c
        c.setFont(SCHRIFT, 6.4)
        c.setFillColor(C_GRAU)
        c.drawString(RAND_L, SEITE_H - RAND_O + 16, self.aktuelle_datei)
        c.setStrokeColor(C_LINIE)
        c.setLineWidth(0.4)
        c.line(RAND_L, SEITE_H - RAND_O + 11, SEITE_B - RAND_R, SEITE_H - RAND_O + 11)

    def neue_seite(self) -> None:
        self.kopfzeile()
        self.fusszeile()
        self.c.showPage()
        self.seite += 1
        self.y = SEITE_H - RAND_O

    def platz(self, zeilen: int = 1) -> None:
        if self.y - zeilen * ZEILE < RAND_U:
            self.neue_seite()


def ersatz_zeilen() -> list[str]:
    """Auflistung der ersetzten Zeichen mit ihrem offiziellen Unicode-Namen."""
    import unicodedata

    if not UNDARSTELLBAR:
        return ["  (keine – alle Zeichen konnten gesetzt werden)"]
    zeilen = []
    for ch in sorted(UNDARSTELLBAR, key=ord):
        try:
            name = unicodedata.name(ch)
        except ValueError:
            name = "?"
        zeilen.append(f"      <U+{ord(ch):04X}>  =  {name}")
    return zeilen


def titelseite(s: Setzer, dateien: list[Eintrag], gesamt_zeilen: int) -> None:
    c = s.c
    mitte = SEITE_B / 2

    c.setFillColor(HexColor("#0d1120"))
    c.rect(0, SEITE_H - 250, SEITE_B, 250, fill=1, stroke=0)

    c.setFillColor(HexColor("#ffffff"))
    c.setFont(SCHRIFT_FETT, 26)
    c.drawCentredString(mitte, SEITE_H - 120, "Modellsammlung")
    c.setFont(SCHRIFT, 10.5)
    c.setFillColor(HexColor("#9aa5c4"))
    c.drawCentredString(mitte, SEITE_H - 145, "Interaktive 3D-Modelle für das Studium")
    c.drawCentredString(mitte, SEITE_H - 162, "Physik · Chemie · Biologie · Medizin")
    c.setFont(SCHRIFT, 8.5)
    c.setFillColor(HexColor("#6b7699"))
    c.drawCentredString(mitte, SEITE_H - 196, "Vollständiger Quellcode")

    y = SEITE_H - 300
    c.setFillColor(C_TEXT)
    c.setFont(SCHRIFT_FETT, 9)
    c.drawString(RAND_L + 20, y, "Diese Datei enthält den kompletten Quellcode des Projekts.")
    y -= 22

    zeilen = [
        "",
        "An eine andere KI übergeben:",
        "",
        "  Der Code ist vollständig und lauffähig. Jede Datei steht unter ihrem",
        "  Pfad, so wie sie im Projekt liegt. Zum Nachbauen genügt es, die Dateien",
        "  mit genau diesen Pfaden anzulegen und danach auszuführen:",
        "",
        "      npm install",
        "      npm run dev",
        "",
        "  Nicht enthalten sind package-lock.json (wird von npm install erzeugt)",
        "  und die PNG-Icons (erzeugt npm run icons aus scripts/icons.py).",
        "",
        "Zeilenumbrüche:",
        "",
        "  Zeilen, die breiter als die Seite sind, werden umgebrochen und in der",
        "  Folgezeile eingerückt fortgesetzt. Erkennbar ist das daran, dass nur die",
        "  erste Zeile eines Umbruchs eine Zeilennummer trägt.",
        "",
        "Sonderzeichen:",
        "",
        "  Einige Emoji lassen sich in keiner verfügbaren PDF-Schrift darstellen.",
        "  Sie stehen deshalb als <U+XXXX> im Text und sind beim Übernehmen durch",
        "  das jeweilige Zeichen zu ersetzen:",
        "",
        *ersatz_zeilen(),
        "",
        "Aufbau des Projekts:",
        "",
        "  src/three/     Viewer und Geometrie-Bausteine",
        "  src/models/    16 Fachmodelle, nach Fachbereich sortiert",
        "  src/pwa/       Installation und Update-Hinweise",
        "  electron/      Desktop-App",
        "  scripts/       Hilfsskripte (Test, Icons, diese PDF)",
    ]
    c.setFont(SCHRIFT, 8)
    for zeile in zeilen:
        # Überschrift ist nur eine nicht eingerückte Zeile mit Doppelpunkt –
        # sonst würde auch eingerückter Fließtext als Überschrift gesetzt.
        ist_ueberschrift = zeile.endswith(":") and not zeile.startswith(" ")
        if ist_ueberschrift:
            c.setFont(SCHRIFT_FETT, 8)
            c.setFillColor(C_AKZENT)
        else:
            c.setFont(SCHRIFT, 8)
            c.setFillColor(C_TEXT)
        c.drawString(RAND_L + 20, y, zeile)
        y -= 11.5

    # Kennzahlen unten
    y -= 14
    c.setStrokeColor(C_LINIE)
    c.line(RAND_L + 20, y, SEITE_B - RAND_R - 20, y)
    y -= 16
    c.setFont(SCHRIFT, 8)
    c.setFillColor(C_GRAU)
    datum = dt.date.today().strftime("%d.%m.%Y")
    c.drawString(RAND_L + 20, y, f"{len(dateien)} Dateien · {gesamt_zeilen:,} Zeilen".replace(",", "."))
    c.drawRightString(SEITE_B - RAND_R - 20, y, f"Stand: {datum}")

    s.fusszeile()
    c.showPage()
    s.seite += 1
    s.y = SEITE_H - RAND_O


def inhaltsverzeichnis(s: Setzer, dateien: list[Eintrag]) -> None:
    c = s.c
    c.setFont(SCHRIFT_FETT, 13)
    c.setFillColor(C_TEXT)
    c.drawString(RAND_L, s.y, "Inhalt")
    s.y -= 24

    for e in dateien:
        if s.y < RAND_U + 20:
            s.fusszeile()
            c.showPage()
            s.seite += 1
            s.y = SEITE_H - RAND_O

        c.setFont(SCHRIFT, 8)
        c.setFillColor(C_TEXT)
        c.drawString(RAND_L, s.y, e.pfad)

        breite = c.stringWidth(e.pfad, SCHRIFT, 8)
        nummer = str(e.startseite)
        nr_breite = c.stringWidth(nummer, SCHRIFT, 8)

        if e.hinweis:
            c.setFont(SCHRIFT, 7)
            c.setFillColor(C_GRAU)
            c.drawString(RAND_L + breite + 8, s.y, e.hinweis)
            breite += 8 + c.stringWidth(e.hinweis, SCHRIFT, 7)

        # Punktlinie bis zur Seitenzahl
        c.setFillColor(C_LINIE)
        x = RAND_L + breite + 5
        ende = SEITE_B - RAND_R - nr_breite - 5
        while x < ende:
            c.circle(x, s.y + 2, 0.35, fill=1, stroke=0)
            x += 4

        c.setFont(SCHRIFT, 8)
        c.setFillColor(C_TEXT)
        c.drawRightString(SEITE_B - RAND_R, s.y, nummer)
        s.y -= 12.5

    s.fusszeile()
    c.showPage()
    s.seite += 1
    s.y = SEITE_H - RAND_O


def datei_setzen(s: Setzer, e: Eintrag) -> None:
    c = s.c
    s.aktuelle_datei = ""

    # Dateiüberschrift – immer oben auf einer neuen Seite
    c.setFillColor(C_KOPF_BG)
    c.rect(RAND_L - 6, s.y - 20, SEITE_B - RAND_L - RAND_R + 12, 30, fill=1, stroke=0)
    c.setFillColor(C_AKZENT)
    c.setFont(SCHRIFT_FETT, 10.5)
    c.drawString(RAND_L, s.y - 4, e.pfad)
    if e.hinweis:
        c.setFont(SCHRIFT, 7.4)
        c.setFillColor(C_GRAU)
        c.drawRightString(SEITE_B - RAND_R, s.y - 4, e.hinweis)
    c.setFont(SCHRIFT, 6.8)
    c.setFillColor(C_GRAU)
    c.drawString(RAND_L, s.y - 15, f"{len(e.zeilen)} Zeilen")
    s.y -= 34

    for nummer, text in e.ausgabe:
        if s.y < RAND_U:
            s.neue_seite()
            # Die laufende Kopfzeile erst ab der zweiten Seite einer Datei –
            # auf der ersten steht der Name bereits in der Überschrift.
            s.aktuelle_datei = e.pfad

        if nummer is not None:
            c.setFont(SCHRIFT, GROESSE * 0.86)
            c.setFillColor(C_NR)
            c.drawRightString(CODE_X - 6, s.y, str(nummer))

        c.setFillColor(C_KOMMENTAR if KOMMENTARZEILE.match(text) else C_TEXT)
        codezeile_zeichnen(c, CODE_X, s.y, text)
        s.y -= ZEILE

    s.kopfzeile()
    s.fusszeile()
    c.showPage()
    s.seite += 1
    s.y = SEITE_H - RAND_O
    s.aktuelle_datei = ""


def seiten_vorausberechnen(dateien: list[Eintrag], startseite: int) -> int:
    """Ermittelt die Startseite jeder Datei, bevor gezeichnet wird."""
    seite = startseite
    for e in dateien:
        e.startseite = seite
        # Erste Seite trägt die Überschrift (34 pt) und daher weniger Codezeilen
        erste = int((SEITE_H - RAND_O - 34 - RAND_U) / ZEILE)
        rest = len(e.ausgabe) - erste
        e.seiten = 1 if rest <= 0 else 1 + -(-rest // ZEILEN_PRO_SEITE)
        seite += e.seiten
    return seite


def main() -> None:
    schriften_laden()
    print("Dateien einlesen:")
    dateien = dateien_sammeln()
    gesamt = sum(len(e.zeilen) for e in dateien)
    print(f"  {len(dateien)} Dateien, {gesamt} Zeilen, Umbruch bei {SPALTEN} Zeichen")

    # Seitenzahlen des Inhaltsverzeichnisses hängen von seiner eigenen Länge ab –
    # deshalb erst dessen Umfang bestimmen, dann die Startseiten berechnen.
    eintraege_pro_seite = int((SEITE_H - RAND_O - 24 - RAND_U) / 12.5)
    toc_seiten = max(1, -(-len(dateien) // eintraege_pro_seite))
    erste_codeseite = 1 + toc_seiten + 1  # Titel + Inhalt + Beginn
    seiten_vorausberechnen(dateien, erste_codeseite)

    c = pdfcanvas.Canvas(str(ZIEL), pagesize=A4)
    c.setTitle("Modellsammlung – Vollständiger Quellcode")
    c.setAuthor("Modellsammlung")
    c.setSubject("Interaktive 3D-Modelle für Physik, Chemie, Biologie und Medizin")

    s = Setzer(c)
    titelseite(s, dateien, gesamt)
    inhaltsverzeichnis(s, dateien)

    for e in dateien:
        if s.seite != e.startseite:
            # Sollte nicht vorkommen; die Vorausberechnung wird dann korrigiert.
            e.startseite = s.seite
        datei_setzen(s, e)

    c.save()
    groesse = ZIEL.stat().st_size / 1024
    print(f"\nGeschrieben: {ZIEL.name}")
    print(f"  {s.seite - 1} Seiten, {groesse:.0f} kB")


if __name__ == "__main__":
    main()
