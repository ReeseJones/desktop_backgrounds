#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
PKG_DIR="$ROOT_DIR/package"
OUT_DIR="$REPO_ROOT/dist"
MAKE_SCREENSHOTS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --out-dir)
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 [--out-dir <dir>] [--screenshots]" >&2
                exit 1
            fi
            OUT_DIR="$2"
            shift 2
            ;;
        --screenshots)
            MAKE_SCREENSHOTS=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--out-dir <dir>] [--screenshots]"
            echo "  --out-dir <dir>  Output directory for release artifacts (default: $REPO_ROOT/dist)"
            echo "  --screenshots    Render 1280x720 store gallery PNGs into <out-dir>/screenshots/"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to parse metadata.json." >&2
    exit 1
fi

read -r PLUGIN_ID PLUGIN_VERSION < <(python3 - "$PKG_DIR/metadata.json" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    meta = json.load(f)
kp = meta["KPlugin"]
print(kp["Id"], kp["Version"])
PY
)

if [[ -z "$PLUGIN_ID" || -z "$PLUGIN_VERSION" ]]; then
    echo "Error: Failed to extract KPlugin.Id and KPlugin.Version from $PKG_DIR/metadata.json" >&2
    exit 1
fi

if [[ ! -s "$REPO_ROOT/LICENSE" ]]; then
    echo "Error: Missing LICENSE file at $REPO_ROOT/LICENSE" >&2
    exit 1
fi

"$ROOT_DIR/scripts/build.sh" --compat

find_qsb() {
    local candidate
    for candidate in \
        "${QSB_BIN:-}" \
        /usr/lib/qt6/bin/qsb \
        /usr/lib64/qt6/bin/qsb \
        /usr/lib/x86_64-linux-gnu/qt6/bin/qsb \
        /usr/lib/aarch64-linux-gnu/qt6/bin/qsb \
        "$(command -v qsb 2>/dev/null || true)" \
        "$(command -v qsb-qt6 2>/dev/null || true)"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    candidate="$(find /usr/lib* -name qsb -type f -executable 2>/dev/null | head -n 1 || true)"
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
    fi
    return 1
}

QSB="$(find_qsb || true)"
if [[ -n "$QSB" ]]; then
    for qsb_file in "$PKG_DIR/contents/shaders"/*.frag.qsb; do
        dump_out="$("$QSB" --dump "$qsb_file" 2>/dev/null || true)"
        qsb_fmt="$(printf '%s\n' "$dump_out" | awk '/QSB_VERSION:/ && !v {v=$2} END {print v}')"
        if [[ -n "$qsb_fmt" ]]; then
            echo "Verified $(basename "$qsb_file"): QSB_VERSION=$qsb_fmt"
            if (( qsb_fmt > 8 )); then
                echo "Error: $(basename "$qsb_file") uses QSB_VERSION=$qsb_fmt (> 8); expected <= 8 for cross-Qt6 compatibility." >&2
                exit 1
            fi
        fi
    done
fi

STAGE_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

cp "$PKG_DIR/metadata.json" "$STAGE_DIR/metadata.json"
cp "$REPO_ROOT/LICENSE" "$STAGE_DIR/LICENSE"
cp -a "$PKG_DIR/contents" "$STAGE_DIR/contents"

mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

TAR_NAME="${PLUGIN_ID}-${PLUGIN_VERSION}.tar.gz"
TAR_PATH="$OUT_DIR/$TAR_NAME"
LATEST_PATH="$OUT_DIR/${PLUGIN_ID}-latest.tar.gz"
SHA_PATH="${TAR_PATH}.sha256"

tar --sort=name -C "$STAGE_DIR" -czf "$TAR_PATH" metadata.json LICENSE contents
cp "$TAR_PATH" "$LATEST_PATH"
(cd "$OUT_DIR" && sha256sum "$TAR_NAME" > "$(basename "$SHA_PATH")")

ARCHIVE_LIST="$(tar -tzf "$TAR_PATH")"
required_entries=(
    "metadata.json"
    "LICENSE"
    "contents/config/main.xml"
    "contents/ui/CosmicShaderView.qml"
    "contents/ui/main.qml"
    "contents/ui/config.qml"
    "contents/shaders/cosmic_nebula.frag.qsb"
    "contents/shaders/event_horizon.frag.qsb"
    "contents/shaders/deep_aurora.frag.qsb"
)
for req in "${required_entries[@]}"; do
    if ! printf '%s\n' "$ARCHIVE_LIST" | grep -Fx "$req" >/dev/null; then
        echo "Error: Missing required archive entry '$req' in $TAR_PATH" >&2
        exit 1
    fi
done

echo "Packaged release archive: $TAR_PATH"
echo "Latest symlink/copy:      $LATEST_PATH"
echo "SHA256 checksum:          $SHA_PATH"

if [[ "$MAKE_SCREENSHOTS" -eq 1 ]]; then
    if ! command -v qml6 >/dev/null 2>&1; then
        echo "Error: qml6 not found in PATH for --screenshots." >&2
        exit 1
    fi
    SHOT_DIR="$OUT_DIR/screenshots"
    mkdir -p "$SHOT_DIR"
    echo "Rendering gallery screenshots into $SHOT_DIR..."
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl \
        qml6 "$ROOT_DIR/scripts/render_preview.qml" -- --out-dir "$SHOT_DIR" --palette default
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl \
        qml6 "$ROOT_DIR/scripts/render_preview.qml" -- --out-dir "$SHOT_DIR" --palette custom
    echo "Screenshots saved in $SHOT_DIR"
fi
