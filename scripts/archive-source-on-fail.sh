#!/bin/bash
# ADDITIV -- bei Build-Fehlschlag Quellcode-PDF + Snapshot archivieren
# Wird von build-app.sh nur bei exit„0 aufgerufen. Ändert keinen bestehenden Build-Erfolgspfad.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EC="${1:-1}"
STAMP="$(date +%Y%m%d-%H%M%S)"
LABEL="build-fail-ec${EC}-$STAMP"

SUPPORT="$HOME/Library/Application Support/FenlynineOS/CodeSnapshot"
ARCH="$SUPPORT/archives"
mkdir -p "$ARCH" "$SUPPORT/current" "$HOME/Downloads"

echo "n Build fehlgeschlagen (exit $EC) -- archiviere Quellcode als PDF…"

# Aktuellen Snapshot sichern
SNAP="$ARCH/source-snap-$LABEL"
mkdir -p "$SNAP"
ditto --norsrc --noextattr "$ROOT/Package.swift" "$SNAP/Package.swift" 2>/dev/null || true
ditto --norsrc --noextattr "$ROOT/Sources" "$SNAP/Sources" 2>/dev/null || true
ditto --norsrc --noextattr "$ROOT/Configuration" "$SNAP/Configuration" 2>/dev/null || true
ditto --norsrc --noextattr "$ROOT/scripts" "$SNAP/scripts" 2>/dev/null || true

# PDF-Katalog
python3 "$ROOT/scripts/generate-code-katalog-pdf.py" \
--out "$ARCH" \
--label "$LABEL" || true

# Kopie nach Downloads
shopt -s nullglob
for pdf in "$ARCH"/*"$LABEL"*.pdf; do
cp "$pdf" "$HOME/Downloads/" || true
echo " PDF-Archiv: $pdf"
done
shopt -u nullglob

# Manifest für Admin-Reiter
MANIFEST="$ARCH/manifest-$LABEL.json"
cat > "$MANIFEST" <<EOF
{
"label": "$LABEL",
"exitCode": $EC,
"timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
"projectRoot": "$ROOT",
"reason": "build-fail"
}
EOF

echo "3 Fail-Archiv abgelegt unter: $ARCH"
exit 0

