#!/bin/bash
# ADDITIV -- kopiert Suite, Installer, Quellcode-Archiv und PDF-Katalog nach ~/Downloads
# Zerstört nichts im Projekt. Nur Ausgabe nach Downloads.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$HOME/Downloads/FenlynineOS-Suite-Export-$STAMP"
APP_SRC="$ROOT/FenlynineOS.app"
mkdir -p "$DEST/App" "$DEST/Quellcode" "$DEST/PDF-Katalog" "$DEST/Installer"

echo "-> Export-Ziel: $DEST"

# 1) App-Bundle
if [[ -d "$APP_SRC" ]]; then
echo "-> App kopieren…"
ditto --norsrc --noextattr "$APP_SRC" "$DEST/App/FenlynineOS.app"
# zusätzlich flach in Downloads für schnellen Zugriff
ditto --norsrc --noextattr "$APP_SRC" "$HOME/Downloads/FenlynineOS.app"
else
echo "n FenlynineOS.app nicht gefunden -- überspringe App-Kopie"
fi

# 2) Vollständiges Quellcode-Archiv (1:1 Nachbau in Xcode/Cursor)
echo "-> Quellcode-ZIP erzeugen…"
ZIP="$DEST/Quellcode/FenlynineOS-Quellcode-komplett-$STAMP.zip"
(
cd "$ROOT"
zip -r -q "$ZIP" \
Package.swift \
Sources \
Configuration \
scripts \
README.md \
CHANGELOG-2.5.0.md \
CHANGELOG-2.4.0.md \
-x "*.DS_Store" -x "**/.build/**" -x "**/DerivedData/**"
)
cp "$ZIP" "$HOME/Downloads/FenlynineOS-Quellcode-komplett-$STAMP.zip"

# 3) PDF-Katalog (gesamter Code + Kategorisierung)
echo "-> PDF-Katalog erzeugen (kann mehrere Minuten dauern)…"
python3 "$ROOT/scripts/generate-code-katalog-pdf.py" \
--out "$DEST/PDF-Katalog" \
--label "export-$STAMP" || {
echo "n PDF-Erzeugung fehlgeschlagen -- Quellcode-ZIP bleibt verfügbar"
}

# Kopie der PDF(s) nach Downloads
shopt -s nullglob
for pdf in "$DEST/PDF-Katalog"/*.pdf; do
cp "$pdf" "$HOME/Downloads/"
echo " PDF -> $HOME/Downloads/$(basename "$pdf")"
done
shopt -u nullglob

# 4) Installationsdatei (Doppelklick / Terminal)
INSTALLER="$DEST/Installer/INSTALLIERE-FenlynineOS.command"
cat > "$INSTALLER" <<'EOF'
#!/bin/bash
# FenlynineOS Legal Suite -- Installer
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# Suite-Export-Ordner = Eltern von Installer/
EXPORT="$(cd "$HERE/.." && pwd)"
APP_SRC="$EXPORT/App/FenlynineOS.app"
TARGET="/Applications/FenlynineOS.app"

echo "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"
echo " FenlynineOS Legal Suite -- Installation"
echo " by Hämmon & Partner"
echo "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"

if [[ ! -d "$APP_SRC" ]]; then
echo "7 App nicht gefunden unter:"
echo " $APP_SRC"
read -r -p "Taste drücken…" _
exit 1
fi

echo "-> Installiere nach $TARGET …"
rm -rf "$TARGET"
ditto --norsrc --noextattr "$APP_SRC" "$TARGET"
xattr -cr "$TARGET" 2>/dev/null || true
codesign --force --sign - --timestamp=none "$TARGET/Contents/MacOS/FenlynineOS" 2>/dev/null || true
codesign --force --sign - --timestamp=none "$TARGET" 2>/dev/null || true

# Quellcode-Snapshot für Admin-Code-Reiter
SUPPORT="$HOME/Library/Application Support/FenlynineOS/CodeSnapshot"
mkdir -p "$SUPPORT/current" "$SUPPORT/archives"
if [[ -d "$EXPORT/Quellcode" ]]; then
# Entpacke neuestes ZIP falls vorhanden
NEWEST="$(ls -t "$EXPORT/Quellcode"/*.zip 2>/dev/null | head -1 || true)"
if [[ -n "${NEWEST:-}" ]]; then
rm -rf "$SUPPORT/current/"*
unzip -q -o "$NEWEST" -d "$SUPPORT/current"
fi
fi
# PDFs archivieren
mkdir -p "$SUPPORT/archives"
cp -f "$EXPORT/PDF-Katalog"/*.pdf "$SUPPORT/archives/" 2>/dev/null || true
cp -f "$EXPORT/PDF-Katalog"/*.pdf "$HOME/Downloads/" 2>/dev/null || true

echo "3 Installation abgeschlossen."
echo " App: $TARGET"
echo " Code-Cache: $SUPPORT/current"
echo " PDF-Archiv: $SUPPORT/archives"
echo ""
echo "Starte FenlynineOS…"
open "$TARGET"
read -r -p "Taste drücken zum Schließen…" _
EOF
chmod +x "$INSTALLER"
# Flache Kopie des Installers nach Downloads
cp "$INSTALLER" "$HOME/Downloads/INSTALLIERE-FenlynineOS.command"
chmod +x "$HOME/Downloads/INSTALLIERE-FenlynineOS.command"

# 5) README
cat > "$DEST/LIESMICH.txt" <<EOF
FenlynineOS Legal Suite -- Export $STAMP
========================================

INHALT
------
App/FenlynineOS.app
-> Die lauffähige Suite (auch nach ~/Downloads/FenlynineOS.app kopiert)

Quellcode/FenlynineOS-Quellcode-komplett-$STAMP.zip
-> 1:1 kompletter Quellcode (Package.swift + Sources + Configuration + scripts)
-> In Cursor/Xcode entpacken = Nachbau ohne Änderungen

PDF-Katalog/
-> Gesamter Code als PDF inkl. detaillierter Funktions-Kategorisierung
-> Welche Datei welche Funktion realisiert

Installer/INSTALLIERE-FenlynineOS.command
-> Doppelklick: installiert nach /Applications und legt Code-Snapshot
für den Admin-Reiter in den Einstellungen ab

NACHBAU IN CURSOR / XCODE
------------------------
1. ZIP entpacken
2. Package.swift öffnen (Swift Package) bzw. Xcode-Projekt
3. swift build / scripts/build-app.sh

ADMIN-CODE-REITER
-----------------
Einstellungen -> „Quellcode (Admin)" -- nur sichtbar für Administrator-Konten.
Zeigt den gesamten Code live; bei Build-Fehlschlag werden PDF-Archive abgelegt.
EOF

# 6) Snapshot für laufende App (Application Support)
SUPPORT="$HOME/Library/Application Support/FenlynineOS/CodeSnapshot"
mkdir -p "$SUPPORT/current" "$SUPPORT/archives"
rm -rf "$SUPPORT/current/"*
mkdir -p "$SUPPORT/current"
(
cd "$ROOT"
ditto --norsrc --noextattr Package.swift "$SUPPORT/current/Package.swift"
ditto --norsrc --noextattr Sources "$SUPPORT/current/Sources"
ditto --norsrc --noextattr Configuration "$SUPPORT/current/Configuration"
ditto --norsrc --noextattr scripts "$SUPPORT/current/scripts"
)
shopt -s nullglob
for pdf in "$DEST/PDF-Katalog"/*.pdf; do
cp "$pdf" "$SUPPORT/archives/"
done
shopt -u nullglob
# Merker: Projektpfad für Live-Sync
echo "$ROOT" > "$SUPPORT/project_root.txt"
echo "$STAMP" > "$SUPPORT/last_export.txt"

echo ""
echo "3 EXPORT FERTIG"
echo " Ordner: $DEST"
echo " App: $HOME/Downloads/FenlynineOS.app"
echo " Installer: $HOME/Downloads/INSTALLIERE-FenlynineOS.command"
echo " Quellcode: $HOME/Downloads/FenlynineOS-Quellcode-komplett-$STAMP.zip"
echo " Support: $SUPPORT"

