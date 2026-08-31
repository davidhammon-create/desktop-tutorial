#!/usr/bin/env python3
"""
Fügt Bild-PDF und Quellcode-PDF zu einem Dokument zusammen.

    npm run pdf:komplett

Voraussetzung: beide Einzeldokumente wurden erzeugt
    npm run shots && npm run pdf:bilder     (Bilder)
    npm run pdf                             (Quellcode)

Ergebnis: Modellsammlung-Komplett.pdf – erst die Bildschirmfotos, dann der
vollständige Quellcode. Die Seitengrößen unterscheiden sich bewusst
(Bilder im Querformat, Code im Hochformat); PDF-Betrachter zeigen jede Seite
in ihrem eigenen Format an.

Benötigt: pip install pypdfium2

Warum pypdfium2 und nicht pypdf: pypdf zieht beim Import das System-Paket
cryptography nach, das in manchen Umgebungen defekt ist und den Prozess mit
einem Rust-Panic beendet. pypdfium2 bringt seine eigene Bibliothek mit und
hat diese Abhängigkeit nicht.
"""
from __future__ import annotations

import sys
from pathlib import Path

import pypdfium2 as pdfium

WURZEL = Path(__file__).resolve().parent.parent
BILDER = WURZEL / "Modellsammlung-Website.pdf"
CODE = WURZEL / "Modellsammlung-Quellcode.pdf"
ZIEL = WURZEL / "Modellsammlung-Komplett.pdf"


def main() -> None:
    fehlend = [p.name for p in (BILDER, CODE) if not p.exists()]
    if fehlend:
        sys.exit(
            "Fehlende Datei(en): " + ", ".join(fehlend) + "\n"
            "Zuerst erzeugen:\n"
            "  npm run build && npm run preview   (Server, in einem Terminal)\n"
            "  npm run shots && npm run pdf:bilder\n"
            "  npm run pdf"
        )

    ziel = pdfium.PdfDocument.new()
    quellen = []  # Referenzen halten, bis gespeichert ist

    for teil in (BILDER, CODE):
        quelle = pdfium.PdfDocument(str(teil))
        quellen.append(quelle)
        ziel.import_pages(quelle)
        print(f"  angehängt: {teil.name} ({len(quelle)} Seiten)")

    ziel.save(str(ZIEL))

    mb = ZIEL.stat().st_size / 1024 / 1024
    print(f"\nGeschrieben: {ZIEL.name}")
    print(f"  {len(ziel)} Seiten, {mb:.1f} MB")


if __name__ == "__main__":
    main()
