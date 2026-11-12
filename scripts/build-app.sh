#!/bin/bash
# Baut FenlynineOS Legal Suite und deployt signiert nach FenlynineOS.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"
APP="$ROOT/FenlynineOS.app"
LEGACY_APP="$ROOT/LegalOS.app"
if [[ ! -d "$APP" && -d "$LEGACY_APP" ]]; then
ditto --norsrc --noextattr "$LEGACY_APP" "$APP"
fi
EXE="$APP/Contents/MacOS/FenlynineOS"
BIN="$ROOT/.build/arm64-apple-macosx/$CONFIG/FenlynineOS"
STAGE="/tmp/FenlynineOS-sign-$$.app"

cleanup() { rm -rf "$STAGE" 2>/dev/null || true; }
# ADDITIV: bei Fehlschlag Quellcode-PDF archivieren (bestehendes cleanup bleibt erhalten)
_fenlynineos_on_exit() {
local ec=$?
cleanup
if [[ $ec -ne 0 ]]; then
bash "$ROOT/scripts/archive-source-on-fail.sh" "$ec" || true
else
# ADDITIV: erfolgreicher Build -> Snapshot für Admin-Code-Reiter aktualisieren
SUPPORT="$HOME/Library/Application Support/FenlynineOS/CodeSnapshot"
mkdir -p "$SUPPORT/current" "$SUPPORT/archives"
ditto --norsrc --noextattr "$ROOT/Package.swift" "$SUPPORT/current/Package.swift" 2>/dev/null || true
ditto --norsrc --noextattr "$ROOT/Sources" "$SUPPORT/current/Sources" 2>/dev/null || true
ditto --norsrc --noextattr "$ROOT/Configuration" "$SUPPORT/current/Configuration" 2>/dev/null || true
ditto --norsrc --noextattr "$ROOT/scripts" "$SUPPORT/current/scripts" 2>/dev/null || true
echo "$ROOT" > "$SUPPORT/project_root.txt"
fi
exit $ec
}
trap _fenlynineos_on_exit EXIT

if [[ ! -d "$APP" ]]; then
echo "7 FenlynineOS.app nicht gefunden unter $APP"
exit 1
fi

echo "-> Swift Build ($CONFIG)…"
swift build -c "$CONFIG"

if [[ ! -f "$BIN" ]]; then
echo "7 Binary nicht gefunden: $BIN"
exit 1
fi

echo "-> Signieren in /tmp…"
codesign --remove-signature "$BIN" 2>/dev/null || true
xattr -cr "$BIN" 2>/dev/null || true

rm -rf "$STAGE"
ditto --norsrc --noextattr "$APP" "$STAGE"
if [[ -f "$ROOT/Configuration/Info.plist" ]]; then
cp "$ROOT/Configuration/Info.plist" "$STAGE/Contents/Info.plist"
fi
# Altes Binary entfernen falls vorhanden
rm -f "$STAGE/Contents/MacOS/LegalOS" "$STAGE/Contents/MacOS/FenlynineOS"
cat "$BIN" > "$STAGE/Contents/MacOS/FenlynineOS"
chmod +x "$STAGE/Contents/MacOS/FenlynineOS"
rm -rf "$STAGE/Contents/_CodeSignature"

STAGE_EXE="$STAGE/Contents/MacOS/FenlynineOS"
xattr -cr "$STAGE" 2>/dev/null || true

codesign --force --sign - --timestamp=none "$STAGE_EXE"
codesign --force --sign - --timestamp=none "$STAGE"
codesign --verify --verbose=2 "$STAGE"

echo "-> Deploy…"
rm -rf "$APP/Contents/_CodeSignature"
ditto --norsrc --noextattr "$STAGE" "$APP"
xattr -cr "$APP" 2>/dev/null || true
# Legacy-Binary entfernen
rm -f "$APP/Contents/MacOS/LegalOS"

if [[ -d "$LEGACY_APP" ]]; then
ditto --norsrc --noextattr "$APP" "$LEGACY_APP"
xattr -cr "$LEGACY_APP" 2>/dev/null || true
fi

codesign --verify --verbose=2 "$APP"
codesign --verify --verbose=2 "$EXE"
echo "3 FenlynineOS.app startbereit -- FenlynineOS Legal Suite by Håmmon & Partner"
echo " open \"$APP\""

