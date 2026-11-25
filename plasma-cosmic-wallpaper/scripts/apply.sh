#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="com.reesedrjones.cosmicspace"
PRESET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 [--preset auto|0|1|2]" >&2
                exit 1
            fi
            PRESET="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--preset auto|0|1|2]"
            echo "  auto: Auto-Cycle (All Scenes, default)"
            echo "  0:    Cosmic Plasma Nebula"
            echo "  1:    Event Horizon Vortex"
            echo "  2:    Deep-Space Plasma Aurora"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--preset auto|0|1|2]" >&2
            exit 1
            ;;
    esac
done

if [[ "$PRESET" == "auto" ]]; then
    PRESET="-1"
fi

if [[ -n "$PRESET" && ! "$PRESET" =~ ^(-1|0|1|2)$ ]]; then
    echo "Error: --preset must be auto, 0, 1, or 2 (got '$PRESET')." >&2
    exit 1
fi

if ! command -v qdbus6 >/dev/null 2>&1; then
    echo "Error: qdbus6 not found in PATH." >&2
    exit 1
fi

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

if [[ -n "$PRESET" ]]; then
    SCRIPT="
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = '${PLUGIN_ID}';
        d.currentConfigGroup = ['Wallpaper', '${PLUGIN_ID}', 'General'];
        d.writeConfig('Preset', ${PRESET});
    }
    "
else
    SCRIPT="
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = '${PLUGIN_ID}';
    }
    "
fi

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT"
echo "Applied $PLUGIN_ID to all desktop containments."
