PLATZHALTER -- BITTE DURCH DIE ORIGINALE ERSETZEN
=================================================

Dieser Ordner enthaelt die Bild-Assets der App. Der Quellcode-Katalog (PDF)
konnte sie nicht enthalten, weil PDFs nur Text uebertragen -- Binaerdateien
wie PNGs fallen dabei heraus.

Betroffen sind genau zwei Bilder, beide nur als Hintergrund-Vorschau in den
Design-Einstellungen verwendet (FenlynineOSAppBackground.swift, Zeile 150/154):

  Assets.xcassets/BigSurDay.imageset/BigSurDay.png
  Assets.xcassets/BigSurNight.imageset/BigSurNight.png

Aktuell liegen dort neutrale Farbverlaeufe, damit das Projekt sofort baut.
Ersetzen Sie beide Dateien durch die Originale aus Ihrem Mac-Projekt:

  <Original-Projekt>/Sources/FenlynineOS/Resources/Assets.xcassets/

Ohne diesen Ordner schlaegt der Build fehl -- Package.swift verweist mit
.process("Resources") darauf. Der Ordner muss also existieren, auch wenn
Sie die Bilder nicht ersetzen. Auf die Funktion der App hat das keinen
Einfluss: es geht ausschliesslich um zwei Vorschaubilder.
