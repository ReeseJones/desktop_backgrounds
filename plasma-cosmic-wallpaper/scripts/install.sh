#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/package"
PLUGIN_ID="com.reesedrjones.cosmicspace"

"$ROOT_DIR/scripts/build.sh"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 not found in PATH." >&2
    exit 1
fi

if kpackagetool6 -t Plasma/Wallpaper --list 2>/dev/null | grep -qx "$PLUGIN_ID"; then
    echo "Upgrading existing Plasma wallpaper package: $PLUGIN_ID"
    kpackagetool6 -t Plasma/Wallpaper -u "$PKG_DIR"
else
    echo "Installing Plasma wallpaper package: $PLUGIN_ID"
    kpackagetool6 -t Plasma/Wallpaper -i "$PKG_DIR"
fi

if ! kpackagetool6 -t Plasma/Wallpaper --list 2>/dev/null | grep -qx "$PLUGIN_ID"; then
    echo "Error: Package $PLUGIN_ID did not appear in kpackagetool6 --list after install." >&2
    exit 1
fi

echo "Installed and verified: $PLUGIN_ID"
