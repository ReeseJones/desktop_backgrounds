#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHADER_DIR="$ROOT_DIR/package/contents/shaders"

find_qsb() {
    if [[ -n "${QSB_BIN:-}" && -x "$QSB_BIN" ]]; then
        printf '%s\n' "$QSB_BIN"
        return 0
    fi
    for candidate in /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb "$(command -v qsb 2>/dev/null || true)" "$(command -v qsb-qt6 2>/dev/null || true)"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

QSB="$(find_qsb || true)"
if [[ -z "$QSB" ]]; then
    echo "Error: Qt6 shader baker (qsb) not found. Install qt6-shadertools." >&2
    exit 1
fi

echo "Using qsb: $QSB"

shopt -s nullglob
shaders=("$SHADER_DIR"/*.frag)
if [[ ${#shaders[@]} -eq 0 ]]; then
    echo "Error: No .frag shaders found in $SHADER_DIR" >&2
    exit 1
fi

for frag in "${shaders[@]}"; do
    out="${frag}.qsb"
    echo "Compiling $(basename "$frag") -> $(basename "$out")"
    "$QSB" --qt6 -o "$out" "$frag"
    if [[ ! -s "$out" ]]; then
        echo "Error: Compiled shader is missing or empty: $out" >&2
        exit 1
    fi
done

echo "All ${#shaders[@]} shaders built successfully."
