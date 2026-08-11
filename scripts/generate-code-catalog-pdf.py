# -*- coding: utf-8 -*-
"""Erzeugt den überarbeiteten FenlynineOS-Quellcode-Katalog als eine PDF."""
import glob, os, re, datetime
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = "/home/user/desktop-tutorial"
SCR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SCR, "FenlynineOSGesamtcode_11.08.26_UEBERARBEITET_komplett.pdf")
LABEL = "Fenlynine-11.08.26-R1 (reorganisiert)"

pdfmetrics.registerFont(TTFont("Mono", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"))
pdfmetrics.registerFont(TTFont("MonoB", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"))

# Datei-Reihenfolge wie im Original-Katalog
order = []
DATEI = re.compile(r'^\s*DATEI:\s+(\S.*?)\s*$')
for f in sorted(glob.glob(SCR + "/extract/Teil_*.txt")):
    for l in open(f):
        m = DATEI.match(l.rstrip())
        if m and m.group(1) not in order:
            order.append(m.group(1))
missing = [p for p in order if not os.path.exists(os.path.join(ROOT, p))]
assert not missing, missing

W, H = A4
ML, MR, MT, MB = 36, 36, 40, 34
SIZE, LEAD = 6.0, 7.0
CONT_INDENT = 8      # Einzug der Fortsetzungszeilen umbrochener Langzeilen
MAXCH = 136          # Zeichen Code pro Zeile: 8 (Prefix) + 136 = 144 passen bei 6pt in den Satzspiegel
page_num = 0
c = canvas.Canvas(OUT, pagesize=A4)
c.setTitle("FenlynineOS Legal Suite – Quellcode-Katalog (überarbeitet)")
c.setPageCompression(1)

y = None
def footer():
    c.setFont("Mono", 6)
    c.setFillGray(0.45)
    c.drawString(ML, 18, f"FenlynineOS Quellcode-Katalog · {LABEL}")
    c.drawRightString(W - MR, 18, f"Seite {page_num}")
    c.setFillGray(0)

def newpage():
    global page_num, y
    if page_num > 0:
        footer()
        c.showPage()
    page_num += 1
    y = H - MT

def line(txt, font="Mono", size=SIZE, lead=LEAD, gray=0.0):
    global y
    if y - lead < MB + 10:
        newpage()
    c.setFont(font, size)
    c.setFillGray(gray)
    c.drawString(ML, y - lead, txt)
    c.setFillGray(0)
    y -= lead

def blank(n=1):
    global y
    y -= LEAD * n

newpage()
# ------------------------------------------------ Titelseite
blank(8)
line("FENLYNINEOS  LEGAL  SUITE", "MonoB", 20, 26)
blank(1)
line("Vollständiger Quellcode-Katalog · ÜBERARBEITETE FASSUNG", "MonoB", 11, 15)
blank(2)
total_lines = 0
for p in order:
    total_lines += sum(1 for _ in open(os.path.join(ROOT, p), encoding="utf-8"))
meta = [
    f"Snapshot-Label:  {LABEL}",
    f"Erzeugt:         {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
    f"Dateien:         {len(order)} · Zeilen (ca.): {total_lines}",
    "Basis:           Snapshot Fenlynine-11.08.26 (10-teiliger PDF-Katalog)",
    "",
    "Zweck: Programmierer-Orientierung und 1:1-Nachbau-Referenz.",
    "Jeder Codeabschnitt ist über 'DATEI:'-Kopfzeilen einer Datei zugeordnet;",
    "Zeilennummern erlauben die maschinelle Rekonstruktion des Quellbaums.",
]
for m in meta:
    line(m, "Mono", 8, 11)

blank(3)
line("WAS WURDE ÜBERARBEITET (Bedienung vereinfacht – ALLE Funktionen unverändert)", "MonoB", 9, 13)
blank(1)
changes = [
"1 · KLARTEXT-NAMEN  Jedes Modul heißt jetzt nach seiner Funktion, die Marke steht in",
"    Klammern: 'Fälle & Mandate (Lexara)', 'Zukunfts-Szenarien (Strategos)',",
"    'Chancen-Radar (Opportunisma)', 'Team & Netzwerk (Organon)'. Suche, Modulliste und",
"    Fenstertitel benutzen überall denselben Namen (vorher zwei verschiedene Label-Systeme).",
"",
"2 · BESCHRIFTETE HAUPTLEISTE  Die linke Studio-Leiste zeigt zu jedem Icon ein Label",
"    (Vorgänge · Lage · Team · Module · Wissen · System) plus erklärende Tooltips.",
"    Vorher: sechs namenlose Icons, die man nur durch Ausprobieren verstand.",
"",
"3 · MODUL-BIBLIOTHEK NEU GEGLIEDERT  Die Zone 'Alle Module' (vorher 'Werkzeuge') ist",
"    nach Tätigkeit sortiert: Fälle & Recht → Strategie & Zukunft → Übersicht & Cockpits →",
"    Kanzlei-Verwaltung → Zusammenarbeit → KI & Compliance → System. Jede Modulzeile trägt",
"    einen Erklärsatz ('Was mache ich hier?'). Der Doppeleintrag 'Lagezentrale' wurde",
"    entfernt (eigene Zone in der Hauptleiste – Funktion unverändert erreichbar).",
"",
"4 · EINSTELLUNGEN GEORDNET  13 flache Reiter jetzt in vier Gruppen: Persönlich ·",
"    KI & Daten · Recht & Markt · System. Auswahl-Persistenz und Inhalte unverändert.",
"",
"5 · TUTORIAL AKTUALISIERT  Die geführte Tour erklärt die neue Navigation.",
"",
"GARANTIE  Kein rawValue, kein Routing-Ziel, kein Deep-Link, keine gespeicherte",
"Einstellung und keine einzige Funktion wurde verändert – nur Namen, Beschriftung,",
"Gruppierung und Layoutbreiten. Geänderte Dateien: AppShell.swift,",
"FenlynineOSStudioShell.swift, EinstellungenView.swift, TutorialView.swift.",
]
for m in changes:
    line(m, "Mono", 7.5, 10)

# ------------------------------------------------ A – Kategorisierung
newpage()
line("A — DATEIÜBERSICHT NACH ORDNERN", "MonoB", 11, 15)
blank(1)
line("Welche Datei realisiert welche Funktion. Reihenfolge wie in Abschnitt B.", "Mono", 7, 10, 0.3)
blank(1)
bygroup = {}
for p in order:
    g = os.path.dirname(p) or "(Wurzel)"
    bygroup.setdefault(g, []).append(p)
for g in sorted(bygroup):
    blank(1)
    line(g, "MonoB", 7.5, 10)
    for p in bygroup[g]:
        n = sum(1 for _ in open(os.path.join(ROOT, p), encoding="utf-8"))
        line(f"   {os.path.basename(p):<58} {n:>6} Zeilen", "Mono", 6.5, 8)

# ------------------------------------------------ B – Quellcode
newpage()
line("B — VOLLSTÄNDIGER QUELLCODE", "MonoB", 11, 15)
blank(1)

def wrap(code):
    """Erste Zeile volle Breite, Fortsetzungen um CONT_INDENT schmaler (sie werden eingerückt)."""
    if len(code) <= MAXCH:
        return [code]
    out = [code[:MAXCH]]
    rest = code[MAXCH:]
    width = MAXCH - CONT_INDENT
    while rest:
        out.append(rest[:width])
        rest = rest[width:]
    return out

for idx, p in enumerate(order):
    src = open(os.path.join(ROOT, p), encoding="utf-8").read().splitlines()
    blank(1)
    if y < MB + 60:
        newpage()
    line(f"DATEI: {p}", "MonoB", 7.5, 11)
    line(f"Zeilen: {len(src)}", "Mono", 6.5, 9, 0.35)
    for i, codeline in enumerate(src, 1):
        prefix = f"{i:>5} | "
        pieces = wrap(codeline.replace("\t", "  "))
        line(prefix + pieces[0])
        for cont in pieces[1:]:
            line(" " * CONT_INDENT + cont)
    if (idx + 1) % 25 == 0:
        print(f"  {idx+1}/{len(order)} Dateien …", flush=True)

footer()
c.save()
print("FERTIG:", OUT, f"{os.path.getsize(OUT)/1e6:.1f} MB, {page_num} Seiten")
