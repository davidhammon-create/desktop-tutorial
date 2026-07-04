#!/bin/bash
# AboWandler für macOS — EIN Doppelklick: baut die App, legt sie in
# ~/Programme ab und startet sie. Kein Öffnen von Xcode nötig.
# Voraussetzung (einmalig): Xcode aus dem Mac App Store installiert.
set -e
cd "$(dirname "$0")/AboWandler"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ Xcode ist nicht installiert. Bitte einmalig kostenlos aus dem Mac App Store laden, danach dieses Skript erneut doppelklicken."
  read -r -p "Enter zum Schließen…"
  exit 1
fi
sudo xcodebuild -license accept 2>/dev/null || true
xcodebuild -runFirstLaunch 2>/dev/null || true

echo "▶ Baue AboWandler für macOS (erster Lauf: 1–3 Minuten)…"
xcodebuild -project AboWandler.xcodeproj \
  -target AboWandler \
  -configuration Release \
  -sdk macosx \
  SYMROOT="$(pwd)/build" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  build | tail -3

APP="$(pwd)/build/Release/AboWandler.app"
if [ ! -d "$APP" ]; then
  echo "❌ Build fehlgeschlagen — bitte AboWandler.xcodeproj einmal in Xcode öffnen und ▶ drücken (zeigt die genaue Fehlermeldung)."
  read -r -p "Enter zum Schließen…"
  exit 1
fi

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/AboWandler.app"
cp -R "$APP" "$HOME/Applications/AboWandler.app"
open "$HOME/Applications/AboWandler.app"
echo ""
echo "✅ Fertig! AboWandler liegt jetzt in deinem Programme-Ordner (~/Applications) und wurde gestartet."
echo "   Ab jetzt einfach dort per Doppelklick öffnen — dieses Skript brauchst du nur nach Code-Updates erneut."
read -r -p "Enter zum Schließen…"
