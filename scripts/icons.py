#!/usr/bin/env python3
"""
Erzeugt die App-Icons (PWA-Manifest, Favicon-Fallback, Electron-Installer)
aus einer einzigen Vorlage: ein Atom-Symbol mit drei Orbitalbahnen.

    python3 scripts/icons.py

Bewusst programmatisch statt als Binärdatei im Repository – so bleibt das Icon
versionierbar und lässt sich in Farbe und Form an einer Stelle ändern.
"""
from pathlib import Path
from PIL import Image, ImageDraw

WURZEL = Path(__file__).resolve().parent.parent
GRUND = (13, 17, 32)          # --bg-2 aus styles.css
KERN = (91, 141, 239)         # --akzent
BAHNEN = [
    ((151, 117, 250), 0),     # violett
    ((81, 207, 102), 60),     # grün
    ((255, 107, 107), 120),   # rot
]

# Intern wird 8-fach überabgetastet und am Ende herunterskaliert – das ergibt
# saubere Kanten ohne Zeichnen von Antialiasing-Details.
SS = 8


def zeichne(groesse: int, rand: float) -> Image.Image:
    """rand = Anteil des Bildes, der als Freiraum um das Motiv bleibt."""
    g = groesse * SS
    bild = Image.new("RGBA", (g, g), (0, 0, 0, 0))
    zeichner = ImageDraw.Draw(bild)

    # Abgerundeter Hintergrund
    radius = int(g * 0.22)
    zeichner.rounded_rectangle([0, 0, g - 1, g - 1], radius=radius, fill=GRUND + (255,))

    mitte = g / 2
    rx = g * (0.5 - rand)          # große Halbachse der Bahnen
    ry = rx * 0.42                 # kleine Halbachse
    strich = max(2, int(g * 0.022))

    for farbe, winkel in BAHNEN:
        # Jede Bahn separat zeichnen und drehen, dann aufaddieren.
        ebene = Image.new("RGBA", (g, g), (0, 0, 0, 0))
        ImageDraw.Draw(ebene).ellipse(
            [mitte - rx, mitte - ry, mitte + rx, mitte + ry],
            outline=farbe + (255,),
            width=strich,
        )
        if winkel:
            ebene = ebene.rotate(winkel, resample=Image.BICUBIC, center=(mitte, mitte))
        bild = Image.alpha_composite(bild, ebene)

    # Kern
    kr = g * 0.115
    ImageDraw.Draw(bild).ellipse(
        [mitte - kr, mitte - kr, mitte + kr, mitte + kr], fill=KERN + (255,)
    )

    return bild.resize((groesse, groesse), Image.LANCZOS)


def speichern(bild: Image.Image, *pfade: Path) -> None:
    for p in pfade:
        p.parent.mkdir(parents=True, exist_ok=True)
        bild.save(p)
        print(f"  {p.relative_to(WURZEL)}  {bild.size[0]}×{bild.size[1]}")


def main() -> None:
    oeffentlich = WURZEL / "public"
    bauen = WURZEL / "build"

    print("App-Icons:")
    # Normale Icons: wenig Rand, Motiv füllt die Fläche
    speichern(zeichne(192, 0.09), oeffentlich / "icon-192.png")
    speichern(zeichne(512, 0.09), oeffentlich / "icon-512.png")
    speichern(zeichne(180, 0.09), oeffentlich / "apple-touch-icon.png")

    # Maskable: Android beschneidet zu einem Kreis, deshalb 20 % Sicherheitsrand
    speichern(zeichne(512, 0.20), oeffentlich / "icon-maskable-512.png")

    # Electron-Installer erwartet mindestens 512 px
    speichern(zeichne(1024, 0.09), bauen / "icon.png")

    print("Fertig.")


if __name__ == "__main__":
    main()
