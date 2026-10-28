#!/usr/bin/env python3
"""
Baut aus den Bildschirmfotos in screenshots/ eine Bild-PDF der Website.

    npm run shots        # Bilder erzeugen (Server muss laufen)
    npm run pdf:bilder   # daraus die PDF bauen

Querformat, weil die Aufnahmen im Seitenverhältnis 16:10 vorliegen – so wird
jedes Bild so groß wie möglich, ohne die Bildunterschrift zu verdrängen.
"""
from __future__ import annotations

import datetime as dt
import json
import sys
from pathlib import Path

from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as pdfcanvas

WURZEL = Path(__file__).resolve().parent.parent
BILDER = WURZEL / "screenshots"
ZIEL = WURZEL / "Modellsammlung-Website.pdf"

SEITE_B, SEITE_H = landscape(A4)
RAND = 30

SANS = "DJSans"
SANS_FETT = "DJSans-Bold"
MONO = "DJMono"

# Farben aus der Oberfläche übernommen, damit Dokument und App zusammenpassen
C_DUNKEL = HexColor("#0d1120")
C_GRUND = HexColor("#070912")
C_TEXT = HexColor("#1a1f2b")
C_GRAU = HexColor("#6b7280")
C_AKZENT = HexColor("#3b6fd4")
C_LINIE = HexColor("#d7dbe2")

FACH_FARBE = {
    "PHYSIK": HexColor("#3b6fd4"),
    "CHEMIE": HexColor("#7c5cd6"),
    "BIOLOGIE": HexColor("#2f9e52"),
    "MEDIZIN": HexColor("#d94a4a"),
}


def schriften_laden() -> None:
    ordner = Path("/usr/share/fonts/truetype/dejavu")
    paare = [
        (SANS, ordner / "DejaVuSans.ttf"),
        (SANS_FETT, ordner / "DejaVuSans-Bold.ttf"),
        (MONO, ordner / "DejaVuSansMono.ttf"),
    ]
    for name, pfad in paare:
        if not pfad.exists():
            sys.exit(f"Schrift fehlt: {pfad}\nUnter Debian/Ubuntu: apt-get install fonts-dejavu-core")
        pdfmetrics.registerFont(TTFont(name, str(pfad)))


def umbrechen(c, text: str, schrift: str, groesse: float, breite: float) -> list[str]:
    """Wortweiser Umbruch anhand der tatsächlichen Textbreite."""
    zeilen: list[str] = []
    aktuell = ""
    for wort in text.split():
        versuch = f"{aktuell} {wort}".strip()
        if c.stringWidth(versuch, schrift, groesse) <= breite:
            aktuell = versuch
        else:
            if aktuell:
                zeilen.append(aktuell)
            aktuell = wort
    if aktuell:
        zeilen.append(aktuell)
    return zeilen


def fusszeile(c, seite: int, gesamt: int) -> None:
    c.setFont(SANS, 7.5)
    c.setFillColor(C_GRAU)
    c.drawString(RAND, 18, "Modellsammlung – Interaktive 3D-Modelle für das Studium")
    c.drawRightString(SEITE_B - RAND, 18, f"{seite} / {gesamt}")


def titelseite(c, anzahl_modelle: int, anzahl_bilder: int) -> None:
    c.setFillColor(C_GRUND)
    c.rect(0, 0, SEITE_B, SEITE_H, fill=1, stroke=0)

    mitte = SEITE_B / 2
    c.setFillColor(HexColor("#ffffff"))
    c.setFont(SANS_FETT, 40)
    c.drawCentredString(mitte, SEITE_H - 165, "Modellsammlung")

    c.setFont(SANS, 15)
    c.setFillColor(HexColor("#9aa5c4"))
    c.drawCentredString(mitte, SEITE_H - 200, "Interaktive 3D-Modelle für das Studium")

    # Fachbereiche als farbige Punkte
    faecher = [("Physik", "#3b6fd4"), ("Chemie", "#7c5cd6"),
               ("Biologie", "#2f9e52"), ("Medizin", "#d94a4a")]
    gesamt_breite = sum(c.stringWidth(n, SANS, 12) + 46 for n, _ in faecher) - 46
    x = mitte - gesamt_breite / 2
    for name, farbe in faecher:
        c.setFillColor(HexColor(farbe))
        c.circle(x + 5, SEITE_H - 243, 4.5, fill=1, stroke=0)
        c.setFillColor(HexColor("#c8d0e4"))
        c.setFont(SANS, 12)
        c.drawString(x + 16, SEITE_H - 247, name)
        x += c.stringWidth(name, SANS, 12) + 46

    c.setStrokeColor(HexColor("#2a3350"))
    c.setLineWidth(0.8)
    c.line(mitte - 150, SEITE_H - 285, mitte + 150, SEITE_H - 285)

    c.setFont(SANS, 11)
    c.setFillColor(HexColor("#8f9ab8"))
    c.drawCentredString(mitte, SEITE_H - 315, "Bildschirmfotos der Anwendung")
    c.drawCentredString(
        mitte, SEITE_H - 338,
        f"{anzahl_modelle} Modelle · {anzahl_bilder} Aufnahmen",
    )

    c.setFont(SANS, 9)
    c.setFillColor(HexColor("#5a6486"))
    datum = dt.date.today().strftime("%d.%m.%Y")
    c.drawCentredString(mitte, 40, f"Stand: {datum}")
    c.showPage()


def uebersichtsseite(c, modelle: list[dict], seite: int, gesamt: int) -> None:
    c.setFillColor(C_TEXT)
    c.setFont(SANS_FETT, 20)
    c.drawString(RAND, SEITE_H - 60, "Was die Anwendung kann")

    spalte_b = (SEITE_B - 2 * RAND - 40) / 2
    y_start = SEITE_H - 105

    bloecke = [
        (
            "Wissenschaftlich belastbare Modelle",
            "Die Geometrie folgt realen Strukturparametern statt gestalterischer Näherung. "
            "Die Wasserstoff-Orbitale werden zur Laufzeit aus den analytischen Lösungen der "
            "Schrödinger-Gleichung gezogen: Die Punktdichte ist die Aufenthaltswahrscheinlichkeit, "
            "die Farbe das Vorzeichen der Wellenfunktion. Die B-DNA nutzt den 140-Grad-Strangversatz, "
            "aus dem große und kleine Furche überhaupt erst entstehen.",
        ),
        (
            "Frei drehbar und zerlegbar",
            "Jedes Modell lässt sich mit der Maus drehen, zoomen und verschieben. Über die "
            "Ebenen-Leiste wird jede Baugruppe einzeln ein- und ausgeblendet – etwa das Benzol "
            "ohne sein π-System oder das Nephron ohne Osmolaritätsgradient. Ein Tempo-Regler "
            "verlangsamt Abläufe bis zum Stillstand.",
        ),
        (
            "Fachtext auf Universitätsniveau",
            "Zu jedem Modell gehören vier Textbereiche: Überblick, Vertiefung mit Herleitungen, "
            "eine Tabelle der prüfungsrelevanten Kennzahlen und typische Klausurfragen. "
            "Die Volltextsuche durchsucht auch diese Texte, nicht nur die Modellnamen.",
        ),
        (
            "Überall nutzbar",
            "Im Browser, als installierte App auf Handy und Desktop oder als eigenständige "
            "Desktop-Anwendung für Windows, macOS und Linux. Einmal installiert, funktioniert "
            "alles vollständig offline.",
        ),
    ]

    for i, (titel, text) in enumerate(bloecke):
        spalte = i % 2
        reihe = i // 2
        x = RAND + spalte * (spalte_b + 40)
        y = y_start - reihe * 118

        c.setFillColor(C_AKZENT)
        c.setFont(SANS_FETT, 12)
        c.drawString(x, y, titel)

        c.setFillColor(C_TEXT)
        c.setFont(SANS, 9.5)
        yy = y - 20
        for zeile in umbrechen(c, text, SANS, 9.5, spalte_b):
            c.drawString(x, yy, zeile)
            yy -= 14

    # --- Alle Modelle nach Fachbereich ---------------------------------------
    y = y_start - 2 * 118 - 26
    c.setStrokeColor(C_LINIE)
    c.setLineWidth(0.6)
    c.line(RAND, y + 16, SEITE_B - RAND, y + 16)

    c.setFillColor(C_TEXT)
    c.setFont(SANS_FETT, 12)
    c.drawString(RAND, y - 6, "Die 16 Modelle")
    y -= 30

    nach_fach: dict[str, list[str]] = {}
    for m in modelle:
        fach = (m.get("fach") or "").split()[-1].upper() if m.get("fach") else "SONSTIGE"
        nach_fach.setdefault(fach, []).append(m.get("titel", ""))

    reihenfolge = ["PHYSIK", "CHEMIE", "BIOLOGIE", "MEDIZIN"]
    spalten = [f for f in reihenfolge if f in nach_fach] or list(nach_fach)
    breite = (SEITE_B - 2 * RAND) / max(1, len(spalten))

    for i, fach in enumerate(spalten):
        x = RAND + i * breite
        c.setFillColor(FACH_FARBE.get(fach, C_AKZENT))
        c.setFont(SANS_FETT, 9)
        c.drawString(x, y, fach)

        yy = y - 16
        c.setFont(SANS, 9)
        for name in nach_fach[fach]:
            c.setFillColor(FACH_FARBE.get(fach, C_AKZENT))
            c.circle(x + 3, yy + 3, 2, fill=1, stroke=0)
            c.setFillColor(C_TEXT)
            # Lange Namen auf die Spaltenbreite kürzen
            text = name
            while c.stringWidth(text, SANS, 9) > breite - 24 and len(text) > 4:
                text = text[:-2]
            if text != name:
                text += "…"
            c.drawString(x + 12, yy, text)
            yy -= 15

    fusszeile(c, seite, gesamt)
    c.showPage()


# Die Aufnahmen entstehen mit 1,5-facher Pixeldichte (2400 px breit). Auf der
# Seite werden sie rund 26 cm breit dargestellt – 1200 px reichen dafür für gut
# 120 dpi und sparen etwa 2/3 der Dateigröße.
MAX_PIXEL = 1200


def bild_laden(pfad: Path) -> tuple[ImageReader, int, int]:
    """
    Lädt ein Bild und verkleinert es bei Bedarf für eine handliche Dateigröße.

    Wichtig: Das Ergebnis wird als PNG-Bytes weitergereicht, nicht als
    PIL-Objekt. reportlab kodiert ein übergebenes PIL-Bild sonst unkomprimiert
    neu – die PDF würde dadurch größer statt kleiner.
    """
    from io import BytesIO

    from PIL import Image

    bild = Image.open(pfad)
    if max(bild.size) > MAX_PIXEL:
        faktor = MAX_PIXEL / max(bild.size)
        neu = (round(bild.width * faktor), round(bild.height * faktor))
        bild = bild.resize(neu, Image.LANCZOS)

    # JPEG statt PNG: reportlab bettet JPEG unverändert ein (DCTDecode), während
    # es PNG dekodiert und neu komprimiert – bei diesen Aufnahmen wird die PDF
    # dadurch etwa dreimal so groß. Qualität 75 reduziert die Dateigröße deutlich
    # bei minimalen Sichtbarkeitsverlust für Oberflächentexte.
    puffer = BytesIO()
    bild.convert("RGB").save(puffer, format="JPEG", quality=75, subsampling=0)
    puffer.seek(0)
    return ImageReader(puffer), bild.width, bild.height


def bildseite(c, eintrag: dict, seite: int, gesamt: int) -> None:
    pfad = WURZEL / eintrag["datei"]
    bild, bb, bh = bild_laden(pfad)

    ist_hochkant = bh > bb

    # --- Kopfbereich ---------------------------------------------------------
    titel = eintrag.get("titel", "")
    fach = (eintrag.get("fach") or "").replace("⚛", "").replace("⬡", "").strip()
    fach_name = fach.split()[-1].upper() if fach else ""

    c.setFillColor(FACH_FARBE.get(fach_name, C_AKZENT))
    c.setFont(SANS_FETT, 8)
    kopf_y = SEITE_H - 40
    if fach_name:
        c.drawString(RAND, kopf_y + 16, fach_name)

    c.setFillColor(C_TEXT)
    c.setFont(SANS_FETT, 17)
    c.drawString(RAND, kopf_y - 2, titel)
    belegt = RAND + c.stringWidth(titel, SANS_FETT, 17)

    # Maßstab direkt hinter den Titel – nicht neben die Bildunterschrift, sonst
    # überlappen beide bei langen Texten.
    massstab = eintrag.get("massstab", "")
    if massstab:
        c.setFont(MONO, 7.5)
        c.setFillColor(C_GRAU)
        c.drawString(belegt + 14, kopf_y + 1, massstab)
        belegt += 14 + c.stringWidth(massstab, MONO, 7.5)

    unter = eintrag.get("untertitel", "")
    if unter:
        breite_unter = c.stringWidth(unter, SANS, 10)
        # Nur setzen, wenn genug Abstand zum Titel bleibt
        if SEITE_B - RAND - breite_unter > belegt + 24:
            c.setFillColor(C_GRAU)
            c.setFont(SANS, 10)
            c.drawRightString(SEITE_B - RAND, kopf_y - 2, unter)

    c.setStrokeColor(C_LINIE)
    c.setLineWidth(0.6)
    c.line(RAND, kopf_y - 14, SEITE_B - RAND, kopf_y - 14)

    # --- Bildunterschrift vorbereiten (bestimmt die verfügbare Bildhöhe) -----
    text = eintrag.get("text", "").strip()
    text_breite = SEITE_B - 2 * RAND
    zeilen = umbrechen(c, text, SANS, 9, text_breite)[:4] if text else []
    text_hoehe = len(zeilen) * 12.5 + (10 if zeilen else 0)

    oben = kopf_y - 26
    unten = 34 + text_hoehe
    max_h = oben - unten
    max_b = SEITE_B - 2 * RAND

    if ist_hochkant:
        # Handy-Aufnahme: schmal, daneben bleibt Platz – Bild mittig setzen
        max_b = max_b * 0.34

    skala = min(max_b / bb, max_h / bh)
    b, h = bb * skala, bh * skala
    x = (SEITE_B - b) / 2
    y = unten + (max_h - h) / 2

    # Feiner Rahmen, damit sich das dunkle Bild vom Papier absetzt
    c.setStrokeColor(HexColor("#c3c9d4"))
    c.setLineWidth(0.7)
    c.rect(x - 0.5, y - 0.5, b + 1, h + 1, fill=0, stroke=1)
    c.drawImage(bild, x, y, width=b, height=h, mask=None)

    # --- Bildunterschrift ----------------------------------------------------
    if zeilen:
        yy = 34 + text_hoehe - 14
        c.setFont(SANS, 9)
        c.setFillColor(C_TEXT)
        for zeile in zeilen:
            c.drawString(RAND, yy, zeile)
            yy -= 12.5

    fusszeile(c, seite, gesamt)
    c.showPage()


def main() -> None:
    schriften_laden()

    verzeichnis_datei = BILDER / "verzeichnis.json"
    if not verzeichnis_datei.exists():
        sys.exit(
            "screenshots/verzeichnis.json fehlt.\n"
            "Zuerst die Bilder erzeugen:\n"
            "  npm run build && npm run preview   (in einem Terminal)\n"
            "  npm run shots                      (in einem zweiten)"
        )

    eintraege = json.loads(verzeichnis_datei.read_text(encoding="utf-8"))
    modelle = [e for e in eintraege if e.get("art") == "modell"]
    gesamt = 2 + len(eintraege)  # Titel + Übersicht + je ein Bild

    c = pdfcanvas.Canvas(str(ZIEL), pagesize=landscape(A4))
    c.setTitle("Modellsammlung – Bildschirmfotos")
    c.setAuthor("Modellsammlung")
    c.setSubject("Interaktive 3D-Modelle für Physik, Chemie, Biologie und Medizin")

    titelseite(c, len(modelle), len(eintraege))
    uebersichtsseite(c, modelle, 2, gesamt)

    for i, eintrag in enumerate(eintraege):
        bildseite(c, eintrag, 3 + i, gesamt)
        print(f"  Seite {3 + i}: {eintrag.get('titel', '')}")

    c.save()
    kb = ZIEL.stat().st_size / 1024
    print(f"\nGeschrieben: {ZIEL.name}")
    print(f"  {gesamt} Seiten, {kb / 1024:.1f} MB")


if __name__ == "__main__":
    main()
