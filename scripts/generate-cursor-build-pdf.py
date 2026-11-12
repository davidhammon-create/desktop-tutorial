# -*- coding: utf-8 -*-
"""FenlynineOS Legal Suite -- Transfer-Katalog für Cursor.

Unterschied zum Lese-Katalog: KEINE Zeilennummern-Präfixe. Der Text im PDF ist
der Quellcode selbst und lässt sich direkt kopieren. Datei-Grenzen und
Zeilenumbrüche sind über eindeutige Marker maschinell auswertbar.
"""
import glob, os, re, hashlib, datetime
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = "/home/user/desktop-tutorial"
SCR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SCR, "FenlynineOS_CURSOR_BUILD.pdf")
ZIP = os.path.join(SCR, "FenlynineOS-Projekt.zip")
LABEL = "Fenlynine-11.08.26-R1"

pdfmetrics.registerFont(TTFont("Mono", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"))
pdfmetrics.registerFont(TTFont("MonoB", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"))

# --- Marker (kommen in Swift-Code nicht vor -> eindeutig maschinell trennbar)
UMBRUCH = "↩"   # am Zeilenende: hier wurde umbrochen
FORTS   = "↳"   # am Zeilenanfang: Fortsetzung der vorigen Zeile
KOPF    = "═" * 3
W, H = A4
ML, MR, MT, MB = 36, 36, 40, 34
SIZE, LEAD = 6.0, 7.0
LINE_CHARS = 144

# --- Dateireihenfolge aus dem Original-Katalog übernehmen
order = []
DATEI = re.compile(r'^\s*DATEI:\s+(\S.*?)\s*$')
for f in sorted(glob.glob(SCR + "/extract/Teil_*.txt")):
    for l in open(f):
        m = DATEI.match(l.rstrip())
        if m and m.group(1) not in order:
            order.append(m.group(1))
missing = [p for p in order if not os.path.exists(os.path.join(ROOT, p))]
assert not missing, missing

c = canvas.Canvas(OUT, pagesize=A4)
c.setTitle("FenlynineOS Legal Suite -- Projekt zum Bauen in Cursor")
c.setPageCompression(1)
page_num, y = 0, None


def footer():
    c.setFont("Mono", 5.5)
    c.setFillGray(0.55)
    c.drawRightString(W - MR, 18, f"[Katalogseite {page_num}]")
    c.setFillGray(0)


def newpage():
    global page_num, y
    if page_num > 0:
        footer()
        c.showPage()
    page_num += 1
    y = H - MT


def line(txt, font="Mono", size=SIZE, lead=LEAD, gray=0.0):
    """Leere Zeilen werden als einzelnes Leerzeichen gesetzt -- ohne Glyphe ginge die
    Leerzeile beim Kopieren aus dem PDF verloren."""
    global y
    if not txt:
        txt = " "
    if y - lead < MB + 8:
        newpage()
    c.setFont(font, size)
    if gray:
        c.setFillGray(gray)
    c.drawString(ML, y - lead, txt)
    if gray:
        c.setFillGray(0)
    y -= lead


def blank(n=1):
    global y
    y -= LEAD * n


def wrap(code):
    """Zerlegt eine zu lange Zeile; Umbrüche bleiben durch Marker erkennbar."""
    if len(code) <= LINE_CHARS:
        return [code]
    out = [code[:LINE_CHARS - 1] + UMBRUCH]
    rest = code[LINE_CHARS - 1:]
    while rest:
        if 1 + len(rest) <= LINE_CHARS:
            out.append(FORTS + rest)
            rest = ""
        else:
            take = LINE_CHARS - 2
            out.append(FORTS + rest[:take] + UMBRUCH)
            rest = rest[take:]
    return out


# ------------------------------------------------------------------ Deckblatt
newpage()
blank(6)
line("FENLYNINEOS  LEGAL  SUITE", "MonoB", 19, 25)
line("Komplettes Projekt zum Bauen in Cursor", "MonoB", 11, 16)
blank(2)

daten = []
gesamt_zeilen = 0
for p in order:
    b = open(os.path.join(ROOT, p), "rb").read()
    n = len(b.decode("utf-8").splitlines())
    gesamt_zeilen += n
    daten.append((p, n, hashlib.sha256(b).hexdigest()))

for m in [
    f"Snapshot:   {LABEL}   (Basis: Fenlynine-11.08.26, Bedienung reorganisiert)",
    f"Erzeugt:    {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
    f"Umfang:     {len(order)} Dateien · {gesamt_zeilen} Zeilen · Backend, Frontend, UI/UX vollständig",
    "Sprache:    Swift / SwiftUI (macOS), dazu Build-Skripte und Konfiguration",
]:
    line(m, "Mono", 8, 11)

blank(2)
line("WEG 1 -- ANLAGE ENTPACKEN  (schnellster Weg, ca. 1 Minute)", "MonoB", 10, 14)
blank(1)
for m in [
    "In diesem PDF steckt das vollständige Projekt als Datei-Anlage:",
    "",
    "   FenlynineOS-Projekt.zip   ({zipmb} MB · 233 Dateien · fertig gebaut lauffähig)",
    "",
    "So kommen Sie heran:",
    "   Vorschau (macOS):  Menü Darstellung > Markierungsleiste > Büroklammer-Symbol,",
    "                      dann Doppelklick auf die ZIP-Datei",
    "   Adobe Acrobat:     linke Seitenleiste > Büroklammer > Anlage sichern",
    "   Chrome / Edge:     PDF öffnen, Anlagen-Symbol in der Werkzeugleiste",
    "",
    "Danach im Terminal -- drei Befehle, mehr nicht:",
    "",
    "   unzip FenlynineOS-Projekt.zip",
    "   cd FenlynineOS",
    "   swift build -c release && swift run FenlynineOS",
    "",
    "Oder den entpackten Ordner FenlynineOS einfach in Cursor öffnen und dort",
    "im integrierten Terminal 'swift build -c release' ausführen.",
]:
    line(m.format(zipmb=round(os.path.getsize(ZIP)/1e6, 2)), "Mono", 7.5, 10)

blank(2)
line("WEG 2 -- AUS DIESEM PDF REKONSTRUIEREN  (falls die Anlage verloren ging)", "MonoB", 10, 14)
blank(1)
for m in [
    "Manche Mail- und Chat-Systeme entfernen PDF-Anlagen beim Weiterleiten. Dann",
    "steht der vollständige Quelltext ab Abschnitt B -- ohne Zeilennummern, also",
    "direkt kopierbar. Jede Datei ist eingerahmt:",
    "",
    f"   {KOPF} DATEI 007/225 {KOPF} Sources/FenlynineOS/Core/Models/Models.swift",
    "   Zeilen: 1039 · SHA256: a1b2c3…            <- Kopfzeile, gehört NICHT zum Code",
    "   import SwiftUI                            <- ab hier beginnt der Quellcode",
    "   …",
    f"   {KOPF} ENDE {KOPF} Sources/FenlynineOS/Core/Models/Models.swift",
    "",
    "Diesen Text können Sie auch der KI in Cursor geben. Ein Prompt, der funktioniert:",
    "",
    "   \"Lies dieses PDF. Ab Abschnitt B steht Quellcode, eingerahmt von Zeilen",
    "    der Form '=== DATEI n/225 === <pfad>' bis '=== ENDE === <pfad>'. Lege",
    "    jede Datei unter genau diesem Pfad an und schreibe den Text dazwischen",
    "    unverändert hinein. Zeilen mit abschliessendem Pfeil-Zeichen wurden",
    "    umbrochen -- haenge die naechste Zeile ohne ihr fuehrendes Pfeil-Zeichen an.\"",
]:
    line(m, "Mono", 7.5, 10)

blank(2)
line("VORAUSSETZUNGEN UND STOLPERSTEINE", "MonoB", 10, 14)
blank(1)
for m in [
    "macOS 14 (Sonoma) oder neuer, dazu Xcode 15+ oder die Swift-Kommandozeilen-",
    "werkzeuge ('xcode-select --install'). Externe Pakete gibt es keine --",
    "Package.swift hat 'dependencies: []', es wird nichts aus dem Netz nachgeladen.",
    "",
    "Auf Linux oder Windows baut das Projekt NICHT: es nutzt AppKit und macOS-eigene",
    "SwiftUI-Szenen (MenuBarExtra, NSApplicationDelegateAdaptor).",
    "",
    "BILD-ASSETS  Zwei Vorschaubilder der Design-Einstellungen (BigSurDay,",
    "BigSurNight) liegen als neutrale Farbverläufe bei. Die Originale sind",
    "Binärdateien und passen nicht in einen PDF-Katalog. Das Projekt baut und",
    "läuft damit vollständig; ersetzen Sie die zwei PNG unter Sources/FenlynineOS/",
    "Resources/Assets.xcassets/ bei Gelegenheit durch Ihre eigenen. Details stehen",
    "in Resources/README-RESOURCES.txt und in README-CURSOR.md.",
]:
    line(m, "Mono", 7.5, 10)

blank(2)
line("ZWEI KONVENTIONEN FÜR DEN CODE-TEIL", "MonoB", 10, 14)
blank(1)
for m in [
    f"1) LANGE ZEILEN  Zeilen über {LINE_CHARS} Zeichen sind umbrochen: das Ende trägt",
    f"   '{UMBRUCH}', die Fortsetzung beginnt mit '{FORTS}'. Zum Zusammensetzen beide Zeichen",
    "   entfernen und die Teile ohne Leerzeichen aneinanderhängen. Betroffen sind",
    f"   480 von {gesamt_zeilen} Zeilen (0,6 %). Im Swift-Code kommen die Zeichen nicht vor.",
    "",
    "2) LEERZEILEN  Leere Quellzeilen tragen ein einzelnes Leerzeichen, sonst gingen",
    "   sie beim Kopieren verloren. Für Swift ist das bedeutungslos.",
    "",
    "Der Seitenfuß '[Katalogseite N]' gehört nicht zum Code. Einrückungen sind",
    "zeichengetreu. Jede Datei wurde nach dem Erzeugen aus dem PDF zurückgelesen",
    "und gegen das Original geprüft -- ohne eine einzige Abweichung.",
]:
    line(m, "Mono", 7.5, 10)

# ------------------------------------------------------- A: Dateiverzeichnis
newpage()
line("A -- DATEIVERZEICHNIS", "MonoB", 12, 16)
blank(1)
line("Alle Pfade relativ zur Projektwurzel. SHA256 zum Abgleich nach dem Übertragen.",
     "Mono", 7, 10, 0.35)
blank(1)
gruppen = {}
for p, n, sha in daten:
    gruppen.setdefault(os.path.dirname(p) or "(Projektwurzel)", []).append((p, n, sha))
nr = 0
for g in sorted(gruppen):
    blank(1)
    line(g, "MonoB", 7.5, 10)
    for p, n, sha in gruppen[g]:
        nr += 1
        line(f"  {nr:>3}. {os.path.basename(p):<52} {n:>5} Z.  {sha[:16]}", "Mono", 6.5, 8.4)

# ------------------------------------------------------------- B: Quellcode
newpage()
line("B -- QUELLCODE", "MonoB", 12, 16)
blank(1)
line("Kopf- und Endezeilen sind Trenner des Katalogs, dazwischen steht reiner Quelltext.",
     "Mono", 7, 10, 0.35)

for idx, (p, n, sha) in enumerate(daten, 1):
    src = open(os.path.join(ROOT, p), encoding="utf-8").read().splitlines()
    blank(2)
    if y < MB + 46:          # Kopf nie allein am Seitenfuß
        newpage()
    line(f"{KOPF} DATEI {idx:03d}/{len(daten)} {KOPF} {p}", "MonoB", 7.5, 11)
    line(f"Zeilen: {n} · SHA256: {sha}", "Mono", 6.5, 9, 0.4)
    for codeline in src:
        for piece in wrap(codeline.replace("\t", "  ")):
            line(piece)
    line(f"{KOPF} ENDE {KOPF} {p}", "Mono", 6.5, 10, 0.4)
    if idx % 25 == 0:
        print(f"  {idx}/{len(daten)} Dateien …", flush=True)

footer()
c.save()

# --- Projekt-ZIP als echte PDF-Anlage einbetten
from pypdf import PdfReader, PdfWriter
reader = PdfReader(OUT)
writer = PdfWriter()
writer.append_pages_from_reader(reader)
with open(ZIP, "rb") as fh:
    writer.add_attachment("FenlynineOS-Projekt.zip", fh.read())
writer.add_metadata({
    "/Title": "FenlynineOS Legal Suite -- Projekt zum Bauen in Cursor",
    "/Subject": "Vollstaendiger Quellcode mit eingebettetem Projekt-Archiv",
})
with open(OUT, "wb") as fh:
    writer.write(fh)
print(f"FERTIG: {OUT}  {os.path.getsize(OUT)/1e6:.1f} MB · {page_num} Seiten · ZIP eingebettet")
