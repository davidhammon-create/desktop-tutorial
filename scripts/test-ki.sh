#!/bin/bash
# Schnelltest: InvokeLLM erreichbar + JSON-Schema (ohne App-Start).
set -euo pipefail

APP_ID="69f2c7c98a9489588db05b5a"
BASE="https://l-os-legal-os-laws-copy-8db05b5a.base44.app/api/apps/${APP_ID}/integration-endpoints/Core/InvokeLLM"

echo "-> Text-Antwort (automatic)…"
curl -sf -X POST "$BASE" \
-H "Content-Type: application/json" \
-H "X-App-Id: $APP_ID" \
-d '{"prompt":"Antworte nur OK","model":"automatic"}' | head -c 120
echo

echo "-> JSON-Schema (automatic)…"
curl -sf -X POST "$BASE" \
-H "Content-Type: application/json" \
-H "X-App-Id: $APP_ID" \
-d '{"prompt":"Gib 1 Test-Argument","model":"automatic","response_json_schema":{"type":"object","properties":{"titel":{"type":"string"},"staerke":{"type":"number"}}}}' | head -c 200
echo

echo "3 InvokeLLM erreichbar"

