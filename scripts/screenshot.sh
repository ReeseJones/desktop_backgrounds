#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_ARG="plasma-cosmic-wallpaper"
PRODUCT_MODE=0
SUITE=""
PRESET=""
TIME_VAL=""
TIMES_VAL=""
CYCLE_TIME=""
SIZE_VAL="1280x720"
BG_COLOR=""
PRIMARY_COLOR=""
SECONDARY_COLOR=""
ACCENT_COLOR=""
BRIGHTNESS=""
STARS=""
BALANCE=""
OUT_FILE=""
OUT_DIR=""
COMPAT_MODE=0
NO_BUILD=0

usage() {
    cat <<'EOF'
Usage: scripts/screenshot.sh [OPTIONS]

Render GPU-accelerated KDE Plasma shader previews or KDE Store product screenshots
headlessly using Qt Quick RHI (OpenGL/Vulkan).

Modes (pick one, default: --suite default):
  --product                  Render official 1280x720 gallery PNGs into dist/screenshots/
  --suite <name>             Batch suite: default | custom | voidtest | blend | soak | quick | product | all
  --preset <auto|-1|0|1|2>   Single-shot / multi-time debug render for one scene

Target & Build:
  --target <dir>             Wallpaper directory (default: plasma-cosmic-wallpaper)
  --compat                   Pass --compat to <target>/scripts/build.sh (QSB v8)
  --no-build                 Skip compiling .frag -> .qsb before rendering

Debug Options (with --preset):
  --time <sec>               Shader uTime in seconds (default: 18.0)
  --times <t1,t2,...>        Comma-separated timestamps (e.g. 18,600,3600)
  --cycle-time <sec>         Auto-Cycle wall-clock time in seconds (e.g. 361.5 for mid-blend)
  --size <WxH>               Output image resolution (default: 1280x720)
  --bg <hex>                 Override uColorBg (Space Void)
  --primary <hex>            Override uColorPrimary
  --secondary <hex>          Override uColorSecondary
  --accent <hex>             Override uColorAccent
  --brightness <num>         Override uBrightness (e.g. 1.0)
  --stars <num>              Override uStarDensity (e.g. 1.0)
  --balance <num>            Override uColorBalance (-1.0 .. 1.0)
  --out <file.png>           Exact output path (single render only)
  --out-dir <dir>            Output directory override
  -h, --help                 Show this help message

Examples:
  ./scripts/screenshot.sh --product
  ./scripts/screenshot.sh --suite soak
  ./scripts/screenshot.sh --preset 1 --times 18,3600 --size 1920x1080
  ./scripts/screenshot.sh --preset auto --cycle-time 361.5 --out previews/blend.png
EOF
}

require_arg() {
    if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Error: Option '$1' requires a value." >&2
        exit 1
    fi
}

abs_path() {
    if command -v realpath >/dev/null 2>&1; then
        realpath -m -- "$1"
    elif [[ "$1" = /* ]]; then
        printf '%s\n' "$1"
    else
        printf '%s/%s\n' "$PWD" "$1"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            require_arg "$@"
            TARGET_ARG="$2"
            shift 2
            ;;
        --product)
            PRODUCT_MODE=1
            shift
            ;;
        --suite)
            require_arg "$@"
            SUITE="$2"
            shift 2
            ;;
        --preset)
            require_arg "$@"
            PRESET="$2"
            shift 2
            ;;
        --time)
            require_arg "$@"
            TIME_VAL="$2"
            shift 2
            ;;
        --times)
            require_arg "$@"
            TIMES_VAL="$2"
            shift 2
            ;;
        --cycle-time)
            require_arg "$@"
            CYCLE_TIME="$2"
            shift 2
            ;;
        --size)
            require_arg "$@"
            SIZE_VAL="$2"
            shift 2
            ;;
        --bg)
            require_arg "$@"
            BG_COLOR="$2"
            shift 2
            ;;
        --primary)
            require_arg "$@"
            PRIMARY_COLOR="$2"
            shift 2
            ;;
        --secondary)
            require_arg "$@"
            SECONDARY_COLOR="$2"
            shift 2
            ;;
        --accent)
            require_arg "$@"
            ACCENT_COLOR="$2"
            shift 2
            ;;
        --brightness)
            require_arg "$@"
            BRIGHTNESS="$2"
            shift 2
            ;;
        --stars)
            require_arg "$@"
            STARS="$2"
            shift 2
            ;;
        --balance)
            require_arg "$@"
            BALANCE="$2"
            shift 2
            ;;
        --out)
            require_arg "$@"
            OUT_FILE="$2"
            shift 2
            ;;
        --out-dir)
            require_arg "$@"
            OUT_DIR="$2"
            shift 2
            ;;
        --compat)
            COMPAT_MODE=1
            shift
            ;;
        --no-build)
            NO_BUILD=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'." >&2
            usage >&2
            exit 1
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required." >&2
    exit 1
fi

if [[ "$TARGET_ARG" = /* ]]; then
    TARGET_DIR="$TARGET_ARG"
else
    TARGET_DIR="$REPO_ROOT/$TARGET_ARG"
fi
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Target wallpaper directory not found: $TARGET_DIR" >&2
    exit 1
fi
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

BUILD_SH="$TARGET_DIR/scripts/build.sh"
RENDER_QML="$TARGET_DIR/scripts/render_preview.qml"

if [[ ! -x "$BUILD_SH" ]]; then
    echo "Error: Missing executable build script: $BUILD_SH" >&2
    exit 1
fi
if [[ ! -f "$RENDER_QML" ]]; then
    echo "Error: Missing preview renderer QML: $RENDER_QML" >&2
    exit 1
fi

if [[ ! "$SIZE_VAL" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    echo "Error: Invalid --size '$SIZE_VAL' (expected WxH, e.g. 1280x720)." >&2
    exit 1
fi
REQ_WIDTH="${BASH_REMATCH[1]}"
REQ_HEIGHT="${BASH_REMATCH[2]}"
if (( REQ_WIDTH < 64 || REQ_HEIGHT < 64 )); then
    echo "Error: --size dimensions must be at least 64x64 (got ${REQ_WIDTH}x${REQ_HEIGHT})." >&2
    exit 1
fi

mode_count=0
[[ "$PRODUCT_MODE" -eq 1 ]] && mode_count=$((mode_count + 1))
[[ -n "$SUITE" ]] && mode_count=$((mode_count + 1))
[[ -n "$PRESET" ]] && mode_count=$((mode_count + 1))
if (( mode_count > 1 )); then
    echo "Error: Choose only one of --product, --suite, or --preset." >&2
    exit 1
fi

if [[ -n "$OUT_FILE" && -z "$PRESET" ]]; then
    echo "Error: --out can only be used in single-shot mode with --preset." >&2
    exit 1
fi

if [[ -n "$OUT_FILE" && "$TIMES_VAL" == *,* ]]; then
    echo "Error: Cannot combine --out with multiple comma-separated --times; use --out-dir instead." >&2
    exit 1
fi

if [[ -n "$SUITE" ]]; then
    case "$SUITE" in
        default|custom|voidtest|blend|soak|quick|product|all)
            ;;
        *)
            echo "Error: Unknown --suite '$SUITE'. Valid suites: default, custom, voidtest, blend, soak, quick, product, all" >&2
            exit 1
            ;;
    esac
fi

if [[ -n "$PRESET" && ! "$PRESET" =~ ^(auto|-1|0|1|2)$ ]]; then
    echo "Error: --preset must be auto, -1, 0, 1, or 2 (got '$PRESET')." >&2
    exit 1
fi

if [[ "$PRODUCT_MODE" -eq 1 ]]; then
    SUITE="product"
    if [[ -z "$OUT_DIR" ]]; then
        OUT_DIR="$REPO_ROOT/dist/screenshots"
    fi
elif [[ -z "$PRESET" && -z "$SUITE" ]]; then
    SUITE="default"
fi

if [[ -z "$OUT_DIR" ]]; then
    OUT_DIR="$TARGET_DIR/previews"
fi
OUT_DIR="$(abs_path "$OUT_DIR")"
mkdir -p "$OUT_DIR"

if [[ -n "$OUT_FILE" ]]; then
    OUT_FILE="$(abs_path "$OUT_FILE")"
    mkdir -p "$(dirname "$OUT_FILE")"
fi

if [[ "$NO_BUILD" -eq 0 ]]; then
    BUILD_ARGS=()
    if [[ "$COMPAT_MODE" -eq 1 ]]; then
        BUILD_ARGS+=(--compat)
    fi
    "$BUILD_SH" "${BUILD_ARGS[@]}"
fi

find_qml6() {
    local candidate
    for candidate in \
        "${QML6_BIN:-}" \
        "$(command -v qml6 2>/dev/null || true)" \
        /usr/lib/qt6/bin/qml \
        /usr/lib64/qt6/bin/qml \
        "$(command -v qml-qt6 2>/dev/null || true)"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

QML_BIN="$(find_qml6 || true)"
if [[ -z "$QML_BIN" ]]; then
    echo "Error: Qt 6 QML runtime (qml6 / qml) not found in PATH." >&2
    exit 1
fi

QML_ARGS=(--out-dir "$OUT_DIR" --width "$REQ_WIDTH" --height "$REQ_HEIGHT")
if [[ -n "$PRESET" ]]; then
    QML_ARGS+=(--preset "$PRESET")
    [[ -n "$TIME_VAL" ]] && QML_ARGS+=(--time "$TIME_VAL")
    [[ -n "$TIMES_VAL" ]] && QML_ARGS+=(--times "$TIMES_VAL")
    [[ -n "$CYCLE_TIME" ]] && QML_ARGS+=(--cycle-time "$CYCLE_TIME")
    [[ -n "$BG_COLOR" ]] && QML_ARGS+=(--bg "$BG_COLOR")
    [[ -n "$PRIMARY_COLOR" ]] && QML_ARGS+=(--primary "$PRIMARY_COLOR")
    [[ -n "$SECONDARY_COLOR" ]] && QML_ARGS+=(--secondary "$SECONDARY_COLOR")
    [[ -n "$ACCENT_COLOR" ]] && QML_ARGS+=(--accent "$ACCENT_COLOR")
    [[ -n "$BRIGHTNESS" ]] && QML_ARGS+=(--brightness "$BRIGHTNESS")
    [[ -n "$STARS" ]] && QML_ARGS+=(--stars "$STARS")
    [[ -n "$BALANCE" ]] && QML_ARGS+=(--balance "$BALANCE")
    [[ -n "$OUT_FILE" ]] && QML_ARGS+=(--out "$OUT_FILE")
else
    QML_ARGS+=(--palette "$SUITE")
fi

RHI_BACKEND="${COSMIC_RHI_BACKEND:-opengl}"
echo "Rendering with $QML_BIN (RHI backend: $RHI_BACKEND, size: ${REQ_WIDTH}x${REQ_HEIGHT})..."

RENDER_LOG=""
if ! RENDER_LOG="$(
    QT_QPA_PLATFORM=offscreen \
    QT_QUICK_BACKEND=rhi \
    QSG_RHI_BACKEND="$RHI_BACKEND" \
    "$QML_BIN" "$RENDER_QML" -- "${QML_ARGS[@]}" 2>&1
)"; then
    printf '%s\n' "$RENDER_LOG" >&2
    echo "Error: QML preview render failed." >&2
    exit 1
fi
printf '%s\n' "$RENDER_LOG"

printf '%s\n' "$RENDER_LOG" | python3 "$REPO_ROOT/scripts/verify_renders.py" \
    --width "$REQ_WIDTH" \
    --height "$REQ_HEIGHT" \
    --log-file -
