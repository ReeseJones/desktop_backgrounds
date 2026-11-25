#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/package"
PLUGIN_ID="com.reesedrjones.cosmicspace"
RELOAD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reload)
            RELOAD=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--reload]"
            echo "  --reload  Restart plasma-plasmashell via systemd --user after installing"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

"$ROOT_DIR/scripts/build.sh"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 not found in PATH." >&2
    exit 1
fi

WAS_INSTALLED=0
if kpackagetool6 -t Plasma/Wallpaper --list 2>/dev/null | grep -qx "$PLUGIN_ID"; then
    WAS_INSTALLED=1
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

if [[ "$RELOAD" -eq 1 ]]; then
    echo "Restarting plasma-plasmashell to reload QML/KConfigXT schemas..."
    systemctl --user restart plasma-plasmashell
elif [[ "$WAS_INSTALLED" -eq 1 ]]; then
    echo "Note: If the wallpaper is already active, run 'systemctl --user restart plasma-plasmashell' (or '$0 --reload') so Plasma reloads updated QML/config schemas."
fi
