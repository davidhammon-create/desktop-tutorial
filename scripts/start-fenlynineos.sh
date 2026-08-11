#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/FenlynineOS.app"
BIN="$ROOT/.build/arm64-apple-macosx/release/FenlynineOS"
if [[ ! -f "$BIN" ]] || [[ "$BIN" -nt "$APP/Contents/MacOS/FenlynineOS" ]] || ! codesign --verify "$BIN" 2>/dev/null; then
"$ROOT/scripts/build-app.sh" release
fi
killall FenlynineOS LegalOS 2>/dev/null || true
sleep 0.5
open "$APP"
sleep 2
pgrep -x FenlynineOS >/dev/null && echo "3 FenlynineOS gestartet" || { echo "7 Start fehlgeschlagen"; exit 1; }

