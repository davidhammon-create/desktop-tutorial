#!/bin/bash
# Baut FenlynineOS, paketiert ein Update und schreibt updates/manifest.json
# Nutzung: scripts/publish-update.sh [version] [build]
# Beispiel: scripts/publish-update.sh 2.1.1 22
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
BUILD="${2:-}"
NOTES="${3:-Modulfenster · Inspektor · Updatesystem · Usability}"

if [[ -z "$VERSION" ]]; then
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Configuration/Info.plist 2>/dev/null || echo "2.1.0")"
fi
if [[ -z "$BUILD" ]]; then
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Configuration/Info.plist 2>/dev/null || echo "21")"
fi

echo "-> Version $VERSION · Build $BUILD"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Configuration/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" Configuration/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" FenlynineOS.app/Contents/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" FenlynineOS.app/Contents/Info.plist 2>/dev/null || true

echo "-> Build & Sign…"
bash "$ROOT/scripts/build-app.sh" release

OUT="$ROOT/updates"
mkdir -p "$OUT"
ZIP="$OUT/FenlynineOS-${VERSION}.app.zip"
rm -f "$ZIP"

echo "-> Zip…"
ditto -c -k --sequesterRsrc --keepParent "$ROOT/FenlynineOS.app" "$ZIP"
SHA="$(shasum -a 256 "$ZIP" | awk '{print $1}')"

# file:// URL mit Prozentkodierung
FILE_URL="$(python3 - <<PY
from urllib.parse import quote
from pathlib import Path
p = Path(r'''$ZIP''').resolve()
print('file://' + quote(str(p)))
PY
)"

RELEASED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cat > "$OUT/manifest.json" <<EOF
{
"version": "$VERSION",
"build": $BUILD,
"releasedAt": "$RELEASED",
"minSystemVersion": "14.0",
"downloadURL": "$FILE_URL",
"sha256": "$SHA",
"mandatory": false,
"notes": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$NOTES")
}
EOF

# Kopie unter Application Support für Geräte ohne Repo-Pfad
SUPP="$HOME/Library/Application Support/FenlynineOS/Updates"
mkdir -p "$SUPP"
cp "$OUT/manifest.json" "$SUPP/manifest.json"
cp "$ZIP" "$SUPP/"

echo "3 Update veröffentlicht"
echo " Manifest: $OUT/manifest.json"
echo " Paket: $ZIP"
echo " SHA256: $SHA"
echo " Support: $SUPP"

