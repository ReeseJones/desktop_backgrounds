#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHADER_DIR="$ROOT_DIR/package/contents/shaders"
COMPAT_MODE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --compat)
            COMPAT_MODE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--compat]"
            echo "  --compat  Bake QSB format v8 (--qsbversion 65) on Qt >= 6.6 for cross-distro Plasma 6 compatibility"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

find_qsb() {
    if [[ -n "${QSB_BIN:-}" && -x "$QSB_BIN" ]]; then
        printf '%s\n' "$QSB_BIN"
        return 0
    fi
    local candidate
    for candidate in \
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
if [[ -z "$QSB" ]]; then
    echo "Error: Qt6 shader baker (qsb) not found. Install qt6-shadertools (or qt6-shader-baker on Ubuntu/Debian)." >&2
    exit 1
fi

echo "Using qsb: $QSB"

QSB_ARGS=(--qt6)
if [[ "$COMPAT_MODE" -eq 1 ]]; then
    QSB_VER="$("$QSB" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || true)"
    if [[ -n "$QSB_VER" ]]; then
        IFS=. read -r q_major q_minor _ <<<"$QSB_VER"
        if (( q_major > 6 || (q_major == 6 && q_minor >= 6) )); then
            QSB_ARGS+=(--qsbversion 65)
            echo "Compat mode: qsb $QSB_VER detected -> baking with --qsbversion 65 (QSB_VERSION 8)"
        else
            echo "Compat mode: qsb $QSB_VER detected -> native QSB version is already <= Qt 6.5 compatible"
        fi
    fi
fi

shopt -s nullglob
shaders=("$SHADER_DIR"/*.frag)
if [[ ${#shaders[@]} -eq 0 ]]; then
    echo "Error: No .frag shaders found in $SHADER_DIR" >&2
    exit 1
fi

for frag in "${shaders[@]}"; do
    out="${frag}.qsb"
    echo "Compiling $(basename "$frag") -> $(basename "$out")"
    "$QSB" "${QSB_ARGS[@]}" -o "$out" "$frag"
    if [[ ! -s "$out" ]]; then
        echo "Error: Compiled shader is missing or empty: $out" >&2
        exit 1
    fi
done

echo "All ${#shaders[@]} shaders built successfully."
