# -*- coding: utf-8 -*-
"""Erzeugt EIN PDF mit allen Verbesserungen -- direkt aus dem Repo, Cursor-tauglich.

Enthält: Deckblatt mit Anleitung, Änderungsübersicht, den vollständigen Quelltext
aller neuen und geänderten Dateien. Kein Zeilennummern-Präfix, damit der Text
direkt kopierbar ist.
"""
import os, re, subprocess, datetime, hashlib
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = "/home/user/desktop-tutorial"
SCR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SCR, "FenlynineOS_Verbesserungen_fuer_Cursor.pdf")
BASIS = "981009b"          # Commit des ursprünglich rekonstruierten Stands

F = "/usr/share/fonts/truetype/dejavu/"
pdfmetrics.registerFont(TTFont("Mono",  F + "DejaVuSansMono.ttf"))
pdfmetrics.registerFont(TTFont("MonoB", F + "DejaVuSansMono-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Sans",  F + "DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("SansB", F + "DejaVuSans-Bold.ttf"))

UMBRUCH, FORTS = "↩", "↳"
KOPF = "═" * 3
W, H = A4
ML, MR, MT, MB = 36, 36, 42, 34
SIZE, LEAD = 6.1, 7.2
LINE_CHARS = 142

def git(*args):
    return subprocess.run(["git", "-C", ROOT, *args],
                          capture_output=True, text=True).stdout.strip()

# ---- Welche Dateien haben sich geändert? ------------------------------------
status = git("diff", "--name-status", BASIS, "HEAD")
neu, geaendert = [], []
for zeile in status.splitlines():
    teile = zeile.split("\t")
    if len(teile) < 2:
        continue
    art, pfad = teile[0], teile[-1]
    if not os.path.exists(os.path.join(ROOT, pfad)):
        continue
    # Binärdateien, erzeugte PDFs und die Generator-Skripte gehören nicht hinein
    if pfad.endswith((".pdf", ".zip", ".png", ".json")) or pfad.startswith("docs/"):
        continue
    if pfad.startswith("scripts/generate-"):
        continue
    (neu if art == "A" else geaendert).append(pfad)

def sortierung(p):
    rang = 0 if p == "Package.swift" else 1 if "/FenlynineOSKern/" in p else \
           2 if p.startswith("Tests/") else 3
    return (rang, p)

neu.sort(key=sortierung)
geaendert.sort(key=sortierung)
alle = [(p, "neu") for p in neu] + [(p, "geändert") for p in geaendert]

# ---- PDF-Grundgerüst --------------------------------------------------------
c = canvas.Canvas(OUT, pagesize=A4)
c.setTitle("FenlynineOS -- Verbesserungen zum Übernehmen in Cursor")
c.setPageCompression(1)
seite, y = 0, None

def fuss():
    c.setFont("Mono", 5.6); c.setFillGray(0.55)
    c.drawString(ML, 18, "FenlynineOS · Verbesserungen · zum Übernehmen in Cursor")
    c.drawRightString(W - MR, 18, f"[Seite {seite}]")
    c.setFillGray(0)

def neueseite():
    global seite, y
    if seite > 0:
        fuss(); c.showPage()
    seite += 1
    y = H - MT

def zeile(txt="", font="Mono", size=SIZE, lead=LEAD, grau=0.0):
    global y
    if not txt:
        txt = " "
    if y - lead < MB + 8:
        neueseite()
    c.setFont(font, size)
    if grau: c.setFillGray(grau)
    c.drawString(ML, y - lead, txt)
    if grau: c.setFillGray(0)
    y -= lead

def leer(n=1):
    global y
    y -= LEAD * n

def umbrich(code):
    code = code.replace("\t", "  ")
    if len(code) <= LINE_CHARS:
        return [code]
    out = [code[:LINE_CHARS - 1] + UMBRUCH]
    rest = code[LINE_CHARS - 1:]
    while rest:
        if 1 + len(rest) <= LINE_CHARS:
            out.append(FORTS + rest); rest = ""
        else:
            n = LINE_CHARS - 2
            out.append(FORTS + rest[:n] + UMBRUCH); rest = rest[n:]
    return out

# ---- Deckblatt --------------------------------------------------------------
neueseite()
leer(5)
zeile("FENLYNINEOS  LEGAL  SUITE", "SansB", 20, 26)
zeile("Verbesserungen zum direkten Übernehmen in Cursor", "SansB", 12, 18)
leer(2)

gesamt_zeilen = sum(len(open(os.path.join(ROOT, p), encoding="utf-8")
                        .read().splitlines()) for p, _ in alle)
for m in [
    f"Basis:      Snapshot Fenlynine-11.08.26 (Commit {BASIS})",
    f"Stand:      {git('rev-parse', '--short', 'HEAD')} · "
    f"{datetime.datetime.now().strftime('%d.%m.%Y %H:%M')}",
    f"Umfang:     {len(neu)} neue und {len(geaendert)} geänderte Dateien · "
    f"{gesamt_zeilen} Zeilen",
    "Repository: Branch claude/incomplete-parts-ctjwzz",
]:
    zeile(m, "Mono", 8.2, 11.5)

leer(2)
zeile("SO ÜBERNEHMEN SIE DIE ÄNDERUNGEN", "SansB", 11, 15)
leer(1)
for m in [
    "Dieses PDF enthält den Quelltext OHNE Zeilennummern -- markierter Text lässt sich",
    "unverändert in eine Datei einfügen. Jede Datei ist eingerahmt:",
    "",
    f"   {KOPF} NEU 003/024 {KOPF} Sources/FenlynineOSKern/Fristen/FristenRechner.swift",
    f"   {KOPF} ENDE {KOPF} Sources/FenlynineOSKern/Fristen/FristenRechner.swift",
    "",
    "NEU bedeutet: Datei anlegen. GEÄNDERT bedeutet: vorhandene Datei vollständig",
    "ersetzen -- der abgedruckte Text ist jeweils der komplette neue Dateiinhalt,",
    "kein Ausschnitt und kein Diff. Sie müssen also nichts zusammensuchen.",
    "",
    "Prompt, der in Cursor funktioniert:",
    "   \"Lies dieses PDF. Ab Abschnitt C steht Quellcode, eingerahmt von Zeilen der",
    "    Form '=== NEU n/m === <pfad>' bzw. '=== GEAENDERT n/m === <pfad>' bis",
    "    '=== ENDE === <pfad>'. Lege jede NEU-Datei unter genau diesem Pfad an und",
    "    ersetze jede GEAENDERT-Datei vollständig durch den abgedruckten Inhalt.",
    "    Zeilen mit abschliessendem Pfeil wurden umbrochen -- haenge die naechste",
    "    Zeile ohne ihr fuehrendes Pfeil-Zeichen an.\"",
    "",
    "Schneller als jedes Kopieren: git clone des oben genannten Branches.",
]:
    zeile(m, "Mono", 7.6, 10.2)

leer(2)
zeile("ZWEI KONVENTIONEN", "SansB", 11, 15)
leer(1)
for m in [
    f"LANGE ZEILEN  Über {LINE_CHARS} Zeichen wird umbrochen: Ende trägt '{UMBRUCH}',",
    f"   Fortsetzung beginnt mit '{FORTS}'. Beide Zeichen kommen im Swift-Code nicht vor.",
    "LEERZEILEN    tragen ein einzelnes Leerzeichen, sonst gingen sie beim Kopieren",
    "   aus dem PDF verloren. Für Swift bedeutungslos.",
]:
    zeile(m, "Mono", 7.6, 10.2)

# ---- A: Was wurde verbessert ------------------------------------------------
neueseite()
zeile("A — WAS VERBESSERT WURDE", "SansB", 13, 18)
leer(1)
abschnitte = [
  ("Drei echte Rechenfehler behoben", [
    "Zwei widersprechende RVG-Tabellen: bei 10.000 € Streitwert lieferte die eine",
    "590 €, die andere 964 €. Jetzt eine einzige Quelle (Anlage 2 RVG, 42 Stufen).",
    "Auslagenpauschale war invertiert: 20 € + 3 % statt 20 %, höchstens 20 €",
    "(Nr. 7002 VV RVG) -- Faktor 4,6 zu hoch.",
    "Verjährung rechnete ab Entstehung; § 199 Abs. 1 BGB beginnt mit Schluss des",
    "Jahres -- bis zu zwölf Monate zu früh.",
  ]),
  ("Fristenberechnung, die es vorher gar nicht gab", [
    "Die gesamte alte Logik war eine Kalendertage-Subtraktion. Neu: §§ 187, 188 BGB,",
    "§ 193 BGB mit Feiertagen je Bundesland, Notfristen nach § 224 ZPO, Höchstfrist",
    "des § 517 ZPO, Osterberechnung nach Meeus/Jones/Butcher. Jede Frist trägt ihre",
    "vollständige Herleitung im Klartext -- Nachweis für die Handakte.",
  ]),
  ("Willkürliche Zahlen durch belegbare Verfahren ersetzt", [
    "Bayes-Faktoren statt erfundener Log-Odds-Koeffizienten: der Anwalt sagt",
    "\"verdoppelt die Chancen\", nicht \"1,6 Log-Odds\".",
    "Beta-Bayes mit Jeffreys-Prior statt erfundener Basisquoten -- verweigert die",
    "Aussage, solange zu wenige eigene Fälle vorliegen.",
    "Gauß-Hermite-Quadratur statt Monte Carlo: 7 Auswertungen statt 3.000,",
    "deterministisch und genauer.",
    "BATNA/ZOPA statt 70-Prozent-Anker; Portfoliovarianz statt Klumpen-Pauschale.",
  ]),
  ("Nachweiskette", [
    "SplitMix64 mit festem Startwert, Rechenbeleg mit Eingabe-Hash und Kernversion,",
    "BelegterWert mit Quelle und Veraltungswarnung, Herkunft je Zahl",
    "(Formel / KI / Mensch / Quelle). Damit ist jede angezeigte Zahl jederzeit",
    "reproduzierbar -- Voraussetzung für Haftungsnachweis und Prüfung.",
  ]),
  ("Bedienung vereinfacht", [
    "Module heißen nach ihrer Funktion, Marke in Klammern. Hauptleiste beschriftet",
    "statt namenloser Icons. Modulbibliothek nach Tätigkeit sortiert, jede Zeile mit",
    "Erklärsatz. Einstellungen von 13 flachen Reitern auf vier Gruppen.",
  ]),
  ("Architektur und Tests", [
    "Rechenlogik in ein eigenes Modul FenlynineOSKern ohne SwiftUI -- dadurch",
    "testbar. Vorher gab es keinen einzigen Test; jetzt 20 Golden-Tests auf den",
    "haftungskritischen Stellen.",
  ]),
]
for titel, punkte in abschnitte:
    leer(1)
    zeile(titel, "SansB", 9, 13)
    for p in punkte:
        zeile("   " + p, "Mono", 7.4, 10)

# ---- B: Dateiverzeichnis ----------------------------------------------------
neueseite()
zeile("B — DATEIVERZEICHNIS", "SansB", 13, 18)
leer(1)
zeile("NEU = anlegen · GEÄNDERT = vollständig ersetzen", "Mono", 7.4, 10, 0.35)
leer(1)
for i, (p, art) in enumerate(alle, 1):
    n = len(open(os.path.join(ROOT, p), encoding="utf-8").read().splitlines())
    marke = "NEU      " if art == "neu" else "GEÄNDERT "
    zeile(f"  {i:>3}. {marke} {p:<66} {n:>5} Z.", "Mono", 6.8, 9)

# ---- C: Quelltext -----------------------------------------------------------
neueseite()
zeile("C — QUELLTEXT", "SansB", 13, 18)
leer(1)
zeile("Zwischen Kopf- und Endezeile steht jeweils der vollständige Dateiinhalt.",
      "Mono", 7.4, 10, 0.35)

for i, (p, art) in enumerate(alle, 1):
    src = open(os.path.join(ROOT, p), encoding="utf-8").read().splitlines()
    sha = hashlib.sha256(open(os.path.join(ROOT, p), "rb").read()).hexdigest()
    leer(2)
    if y < MB + 46:
        neueseite()
    marke = "NEU" if art == "neu" else "GEAENDERT"
    zeile(f"{KOPF} {marke} {i:03d}/{len(alle):03d} {KOPF} {p}", "MonoB", 7.6, 11)
    zeile(f"Zeilen: {len(src)} · SHA256: {sha}", "Mono", 6.4, 9, 0.4)
    for cl in src:
        for stueck in umbrich(cl):
            zeile(stueck)
    zeile(f"{KOPF} ENDE {KOPF} {p}", "Mono", 6.4, 10, 0.4)
    if i % 10 == 0:
        print(f"  {i}/{len(alle)} Dateien …", flush=True)

fuss()
c.save()
print(f"FERTIG: {OUT}  {os.path.getsize(OUT)/1e6:.2f} MB · {seite} Seiten · "
      f"{len(neu)} neu, {len(geaendert)} geändert")
