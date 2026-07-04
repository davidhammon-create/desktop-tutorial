#!/bin/bash
# AboWandler aufs iPhone — EIN Doppelklick auf dem Mac: baut die App und
# installiert sie direkt auf das per Kabel verbundene iPhone.
# Voraussetzungen (einmalig):
#   1. Xcode installiert (Mac App Store) und dort unter
#      Settings → Accounts deine Apple-ID hinzugefügt.
#   2. iPhone per Kabel verbunden, entsperrt, "Diesem Computer vertrauen".
#
# Optional: Deine Team-ID hier eintragen (Xcode → Settings → Accounts →
# Team anklicken → "Team ID"), sonst versucht es das Skript automatisch.
TEAM_ID=""

set -e
cd "$(dirname "$0")/AboWandler"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ Xcode ist nicht installiert. Bitte einmalig kostenlos aus dem Mac App Store laden."
  read -r -p "Enter zum Schließen…"
  exit 1
fi

echo "▶ Suche verbundenes iPhone…"
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /connected/ {print $NF; exit}')
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ {print $NF; exit}')
fi
if [ -z "$DEVICE_ID" ]; then
  echo "❌ Kein iPhone gefunden. Kabel verbinden, iPhone entsperren, 'Vertrauen' bestätigen — dann erneut doppelklicken."
  read -r -p "Enter zum Schließen…"
  exit 1
fi
echo "   Gefunden: $DEVICE_ID"

TEAM_ARG=""
if [ -n "$TEAM_ID" ]; then TEAM_ARG="DEVELOPMENT_TEAM=$TEAM_ID"; fi

echo "▶ Baue & signiere AboWandler für iOS (erster Lauf: 1–3 Minuten)…"
xcodebuild -project AboWandler.xcodeproj \
  -target AboWandler \
  -configuration Release \
  -sdk iphoneos \
  SYMROOT="$(pwd)/build-ios" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  $TEAM_ARG \
  build | tail -3

APP="$(pwd)/build-ios/Release-iphoneos/AboWandler.app"
if [ ! -d "$APP" ]; then
  echo "❌ Build/Signierung fehlgeschlagen. Häufigste Ursache: Apple-ID fehlt in Xcode"
  echo "   (Xcode → Settings → Accounts) oder Team nicht gesetzt. Fallback: Projekt"
  echo "   einmal in Xcode öffnen, Team wählen, ▶ drücken — danach klappt dieses Skript."
  read -r -p "Enter zum Schließen…"
  exit 1
fi

echo "▶ Installiere auf dem iPhone…"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
echo ""
echo "✅ Fertig! AboWandler ist auf deinem iPhone installiert."
echo "   Beim ersten Öffnen: Einstellungen → Allgemein → VPN & Geräteverwaltung → deinem Profil vertrauen."
echo "   Hinweis: Mit kostenloser Apple-ID läuft die App 7 Tage — danach dieses Skript einfach erneut doppelklicken."
read -r -p "Enter zum Schließen…"
