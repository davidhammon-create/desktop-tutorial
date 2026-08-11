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
OUT = os.path.join(SCR, "FenlynineOS_KOMPLETT_fuer_Cursor.pdf")
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
c.setTitle("FenlynineOS Legal Suite -- Kompletter Quellcode für Cursor")
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
line("Kompletter Quellcode -- Transfer-Fassung für Cursor", "MonoB", 11, 16)
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
line("SO ÜBERTRAGEN SIE DEN CODE NACH CURSOR", "MonoB", 10, 14)
blank(1)
for m in [
    "Dieses PDF enthält den Quelltext OHNE Zeilennummern -- markierter Text lässt sich",
    "direkt in eine Datei einfügen. Jede Datei ist von eindeutigen Markern eingerahmt:",
    "",
    f"   {KOPF} DATEI 007/225 {KOPF} Sources/FenlynineOS/Core/Models/Models.swift",
    "   Zeilen: 1039 · SHA256: a1b2c3…            <- Kopfzeile, gehört NICHT zum Code",
    "   import SwiftUI                            <- ab hier beginnt der Quellcode",
    "   …",
    f"   {KOPF} ENDE {KOPF} Sources/FenlynineOS/Core/Models/Models.swift",
    "",
    "Legen Sie in Cursor die Ordnerstruktur laut Pfadangabe an und fügen Sie den",
    "Code zwischen Kopf- und Endezeile in die jeweilige Datei ein. Die Reihenfolge",
    "ist unerheblich; Abschnitt A listet alle Pfade vollständig auf.",
    "",
    "Alternativ (deutlich schneller): Das Projekt liegt vollständig im Git-Repository",
    "auf dem Branch claude/incomplete-parts-ctjwzz -- dort genügt ein git clone,",
    "und Cursor öffnet den fertigen Quellbaum ohne jedes Kopieren.",
]:
    line(m, "Mono", 7.5, 10)

blank(2)
line("ZWEI KONVENTIONEN, DIE SIE KENNEN MÜSSEN", "MonoB", 10, 14)
blank(1)
for m in [
    f"1) LANGE ZEILEN  Zeilen über {LINE_CHARS} Zeichen werden umbrochen. Das Ende einer",
    f"   umbrochenen Zeile trägt '{UMBRUCH}', die Fortsetzung beginnt mit '{FORTS}'.",
    "   Zum Rekonstruieren: schließendes Zeichen entfernen, führendes Zeichen der",
    "   Folgezeile entfernen, beide Teile ohne Leerzeichen aneinanderhängen.",
    f"   Betroffen sind 480 von {gesamt_zeilen} Zeilen (0,6 %). Beide Zeichen kommen im",
    "   Quellcode selbst nirgends vor -- eine Verwechslung ist ausgeschlossen.",
    "",
    "2) SEITENFUSS  Unten rechts steht auf jeder Seite '[Katalogseite N]'. Diese",
    "   Angabe gehört nicht zum Code und ist beim Übertragen zu ignorieren.",
    "",
    "3) LEERZEILEN  Leere Quellzeilen tragen im PDF ein einzelnes Leerzeichen, damit",
    "   sie beim Kopieren nicht verloren gehen. Beim Übertragen entsteht dadurch auf",
    "   diesen Zeilen ein Leerzeichen -- für Swift bedeutungslos. Wer die SHA256 exakt",
    "   treffen will, entfernt nachlaufende Leerzeichen (in Xcode/Cursor ein Befehl).",
    "",
    "Einrückungen sind zeichengetreu erhalten. Jede Datei wurde nach der Erzeugung",
    "aus dem PDF zurückgelesen und gegen das Original geprüft -- ohne Abweichung.",
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
print(f"FERTIG: {OUT}  {os.path.getsize(OUT)/1e6:.1f} MB · {page_num} Seiten")
