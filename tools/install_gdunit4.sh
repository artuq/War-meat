#!/usr/bin/env bash
# Pobiera i instaluje gdUnit4 jako addon Godota
# Uruchom raz z katalogu projektu: bash tools/install_gdunit4.sh

set -e

GDUNIT_VERSION="v4.4.0"
GDUNIT_URL="https://github.com/godot-gdunit-labs/gdUnit4/releases/download/${GDUNIT_VERSION}/gdUnit4.zip"
TMP="/tmp/gdunit4.zip"

echo "=== Instalacja gdUnit4 ${GDUNIT_VERSION} ==="

curl -L -o "$TMP" "$GDUNIT_URL"
unzip -q -o "$TMP" -d addons/
rm "$TMP"

echo "✓ gdUnit4 zainstalowany w addons/gdunit4/"
echo ""
echo "Następnie w Godot Editor:"
echo "  Project → Project Settings → Plugins → gdUnit4 → Enable"
