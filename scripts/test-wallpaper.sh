#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_ARG="plasma-cosmic-wallpaper"
SUITE="quick"
NO_RENDER=0
OUT_DIR=""

usage() {
    cat <<'EOF'
Usage: scripts/test-wallpaper.sh [OPTIONS]

Run end-to-end validation for a Plasma 6 shader wallpaper directory:
  1. Bash (bash -n) and Python (python3 -m ast) syntax check on repo & target scripts
  2. metadata.json & KConfig main.xml schema validation
  3. GLSL -> QSB shader compilation (--compat) & QSB_VERSION <= 8 check
  4. QML linting (qmllint) across UI & preview scripts
  5. Offscreen GPU shader render suite & non-blank PNG check

Options:
  --target <dir>                     Wallpaper directory (default: plasma-cosmic-wallpaper)
  --suite <quick|full|product|soak>  Offscreen render suite (default: quick)
  --no-render                        Skip Check 5 (useful on headless CPU-only hosts)
  --out-dir <dir>                    Directory for rendered test PNGs (default: <target>/previews/test-run)
  -h, --help                         Show this help message
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
        --suite)
            require_arg "$@"
            SUITE="$2"
            shift 2
            ;;
        --no-render)
            NO_RENDER=1
            shift
            ;;
        --out-dir)
            require_arg "$@"
            OUT_DIR="$2"
            shift 2
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

case "$SUITE" in
    quick|product|soak)
        RENDER_SUITE="$SUITE"
        ;;
    full)
        RENDER_SUITE="all"
        ;;
    *)
        echo "Error: Unknown --suite '$SUITE'. Valid values: quick, full, product, soak" >&2
        exit 1
        ;;
esac

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

if [[ -z "$OUT_DIR" ]]; then
    OUT_DIR="$TARGET_DIR/previews/test-run"
fi
OUT_DIR="$(abs_path "$OUT_DIR")"

echo "Testing wallpaper: $TARGET_DIR (suite: $SUITE)"

# Check 1: Script syntax (Bash + Python)
shopt -s nullglob
sh_files=("$REPO_ROOT/scripts"/*.sh "$TARGET_DIR/scripts"/*.sh)
py_files=("$REPO_ROOT/scripts"/*.py "$TARGET_DIR/scripts"/*.py)
shopt -u nullglob
if [[ ${#sh_files[@]} -eq 0 && ${#py_files[@]} -eq 0 ]]; then
    echo "[FAIL] Check 1 (Script syntax): No shell or Python scripts found." >&2
    exit 1
fi
for shf in "${sh_files[@]}"; do
    if ! bash -n "$shf"; then
        echo "[FAIL] Check 1 (Script syntax): Syntax error in $shf" >&2
        exit 1
    fi
done
if [[ ${#py_files[@]} -gt 0 ]]; then
    if ! command -v python3 >/dev/null 2>&1; then
        echo "[FAIL] Check 1 (Script syntax): python3 not found in PATH." >&2
        exit 1
    fi
    for pyf in "${py_files[@]}"; do
        if ! python3 -m ast "$pyf" >/dev/null; then
            echo "[FAIL] Check 1 (Script syntax): Syntax error in $pyf" >&2
            exit 1
        fi
    done
fi
echo "[PASS] Check 1 (Script syntax): Checked ${#sh_files[@]} shell and ${#py_files[@]} Python script(s)."

# Check 2: Metadata & KConfig XML
META_JSON="$TARGET_DIR/package/metadata.json"
MAIN_XML="$TARGET_DIR/package/contents/config/main.xml"
if ! python3 "$REPO_ROOT/scripts/metadata_tool.py" validate "$META_JSON" "$MAIN_XML"; then
    echo "[FAIL] Check 2 (Metadata & KConfig XML) failed." >&2
    exit 1
fi

# Check 3: Shader compilation & QSB_VERSION <= 8
BUILD_SH="$TARGET_DIR/scripts/build.sh"
if [[ ! -x "$BUILD_SH" ]]; then
    echo "[FAIL] Check 3 (Shaders): Missing executable $BUILD_SH" >&2
    exit 1
fi
"$BUILD_SH" --compat

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
    return 1
}

QSB="$(find_qsb || true)"
if [[ -z "$QSB" ]]; then
    echo "[FAIL] Check 3 (Shaders): qsb binary not found to verify QSB_VERSION." >&2
    exit 1
fi

shopt -s nullglob
frags=("$TARGET_DIR/package/contents/shaders"/*.frag)
shopt -u nullglob
if [[ ${#frags[@]} -eq 0 ]]; then
    echo "[FAIL] Check 3 (Shaders): No .frag shaders found in $TARGET_DIR/package/contents/shaders" >&2
    exit 1
fi

for frag in "${frags[@]}"; do
    qsb_out="${frag}.qsb"
    if [[ ! -s "$qsb_out" ]]; then
        echo "[FAIL] Check 3 (Shaders): Missing or empty $qsb_out" >&2
        exit 1
    fi
    dump_out="$("$QSB" --dump "$qsb_out" 2>/dev/null || true)"
    qsb_fmt="$(printf '%s\n' "$dump_out" | awk '/QSB_VERSION:/ && !v {v=$2} END {print v}')"
    if [[ -z "$qsb_fmt" ]]; then
        echo "[FAIL] Check 3 (Shaders): Unable to read QSB_VERSION from $qsb_out" >&2
        exit 1
    fi
    if (( qsb_fmt > 8 )); then
        echo "[FAIL] Check 3 (Shaders): $(basename "$qsb_out") has QSB_VERSION=$qsb_fmt (> 8)." >&2
        exit 1
    fi
done
echo "[PASS] Check 3 (Shaders & QSB compatibility): All ${#frags[@]} shader(s) built with QSB_VERSION <= 8."

# Check 4: QML linting
find_qmllint() {
    local candidate
    for candidate in \
        "${QMLLINT_BIN:-}" \
        /usr/lib/qt6/bin/qmllint \
        /usr/lib64/qt6/bin/qmllint \
        /usr/lib/x86_64-linux-gnu/qt6/bin/qmllint \
        /usr/lib/aarch64-linux-gnu/qt6/bin/qmllint \
        "$(command -v qmllint 2>/dev/null || true)" \
        "$(command -v qmllint-qt6 2>/dev/null || true)"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

QMLLINT="$(find_qmllint || true)"
if [[ -z "$QMLLINT" ]]; then
    echo "[SKIP] Check 4 (QML lint): qmllint not installed."
else
    shopt -s nullglob
    qml_files=("$TARGET_DIR/package/contents/ui"/*.qml "$TARGET_DIR/scripts"/*.qml)
    shopt -u nullglob
    if [[ ${#qml_files[@]} -eq 0 ]]; then
        echo "[FAIL] Check 4 (QML lint): No QML files found." >&2
        exit 1
    fi
    for qml_file in "${qml_files[@]}"; do
        lint_args=()
        if [[ "$(basename "$qml_file")" == "main.qml" ]]; then
            # KConfigPropertyMap exposes dynamic properties from main.xml at runtime
            lint_args+=(--missing-property disable)
        fi
        lint_out=""
        if ! lint_out="$("$QMLLINT" "${lint_args[@]}" "$qml_file" 2>&1)"; then
            printf '%s\n' "$lint_out" >&2
            echo "[FAIL] Check 4 (QML lint): qmllint failed on $qml_file" >&2
            exit 1
        fi
        if [[ -n "$lint_out" ]]; then
            printf '%s\n' "$lint_out" >&2
            echo "[FAIL] Check 4 (QML lint): Unexpected warnings on $qml_file" >&2
            exit 1
        fi
    done
    echo "[PASS] Check 4 (QML lint): Clean across ${#qml_files[@]} file(s)."
fi

# Check 5: Offscreen GPU shader rendering
if [[ "$NO_RENDER" -eq 1 ]]; then
    echo "[SKIP] Check 5 (Offscreen GPU render): Skipped via --no-render."
else
    "$REPO_ROOT/scripts/screenshot.sh" \
        --target "$TARGET_DIR" \
        --suite "$RENDER_SUITE" \
        --no-build \
        --out-dir "$OUT_DIR"
    echo "[PASS] Check 5 (Offscreen GPU render): Suite '$RENDER_SUITE' verified in $OUT_DIR"
fi

echo ""
echo "All checks completed for $(basename "$TARGET_DIR")."
if [[ "$NO_RENDER" -eq 0 ]]; then
    echo "Rendered PNGs ready for visual inspection: $OUT_DIR"
fi
