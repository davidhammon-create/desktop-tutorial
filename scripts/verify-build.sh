#!/bin/bash
# Sicherheits-Check vor manuellem Testen: kompiliert ohne Fehler.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "-> Swift Build (Debug)…"
swift build 2>&1

echo "-> Swift Build (Release)…"
swift build -c release 2>&1

echo "3 Build erfolgreich (Debug + Release) -- App kann gestartet werden."
echo " Signiertes Bundle: ./scripts/build-app.sh"
echo " Start: ./scripts/start-fenlynineos.sh"

