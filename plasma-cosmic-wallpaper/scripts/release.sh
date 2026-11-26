#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
META_JSON="$ROOT_DIR/package/metadata.json"

BUMP_ARG=""
SCREENSHOTS=0
NO_PUSH=0
DRY_RUN=0
OPEN_STORE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        patch|minor|major|same)
            BUMP_ARG="$1"
            shift
            ;;
        --screenshots)
            SCREENSHOTS=1
            shift
            ;;
        --no-push)
            NO_PUSH=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --open)
            OPEN_STORE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [patch|minor|major|same|<X.Y.Z>] [--screenshots] [--no-push] [--dry-run] [--open]"
            echo "  patch|minor|major|same|<X.Y.Z>  Version bump mode (prompts interactively if omitted)"
            echo "  --screenshots                   Also render 1280x720 store screenshots into dist/screenshots/"
            echo "  --no-push                       Commit and tag locally without pushing to origin"
            echo "  --dry-run                       Preview target version and package without editing metadata or tagging"
            echo "  --open                          Open the KDE Store product page in your browser"
            exit 0
            ;;
        *)
            if [[ -z "$BUMP_ARG" && "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                BUMP_ARG="$1"
                shift
            else
                echo "Error: Unknown argument or invalid version '$1'." >&2
                exit 1
            fi
            ;;
    esac
done

read -r PLUGIN_ID CURRENT_VERSION < <(python3 "$REPO_ROOT/scripts/metadata_tool.py" get "$META_JSON" --field id-version)

if [[ -z "$BUMP_ARG" ]]; then
    if [[ ! -t 0 ]]; then
        echo "Error: Version bump argument required in non-interactive mode (patch|minor|major|same|X.Y.Z)." >&2
        exit 1
    fi
    echo "Current version in metadata.json: $CURRENT_VERSION"
    read -r -p "Select bump [patch / minor / major / same / X.Y.Z] (default: patch): " BUMP_ARG
    BUMP_ARG="${BUMP_ARG:-patch}"
fi

NEW_VERSION="$(python3 "$REPO_ROOT/scripts/metadata_tool.py" bump "$CURRENT_VERSION" "$BUMP_ARG")"

TAG="v${NEW_VERSION}"
echo "Release target: $PLUGIN_ID $CURRENT_VERSION -> $NEW_VERSION ($TAG)"

if [[ "$DRY_RUN" -eq 0 ]]; then
    dirty="$(git -C "$REPO_ROOT" status --porcelain)"
    if [[ -n "$dirty" ]]; then
        echo "Error: Working tree has uncommitted changes. Commit or stash before releasing:" >&2
        printf '%s\n' "$dirty" >&2
        exit 1
    fi
    if git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
        echo "Error: Git tag '$TAG' already exists locally." >&2
        exit 1
    fi
    if [[ "$NO_PUSH" -eq 0 ]] && git -C "$REPO_ROOT" ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
        echo "Error: Git tag '$TAG' already exists on origin." >&2
        exit 1
    fi

    if [[ "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
        python3 "$REPO_ROOT/scripts/metadata_tool.py" set-version "$META_JSON" "$NEW_VERSION"
        echo "Updated KPlugin.Version -> $NEW_VERSION in metadata.json"
    fi
fi

PKG_ARGS=()
if [[ "$SCREENSHOTS" -eq 1 ]]; then
    PKG_ARGS+=(--screenshots)
fi
"$ROOT_DIR/scripts/package.sh" "${PKG_ARGS[@]}"

TAR_PATH="$REPO_ROOT/dist/${PLUGIN_ID}-${NEW_VERSION}.tar.gz"
if [[ "$DRY_RUN" -eq 1 && "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
    TAR_PATH="$REPO_ROOT/dist/${PLUGIN_ID}-${CURRENT_VERSION}.tar.gz"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
    if [[ -n "$(git -C "$REPO_ROOT" status --porcelain -- "$META_JSON")" ]]; then
        git -C "$REPO_ROOT" add "$META_JSON"
        git -C "$REPO_ROOT" commit -m "Release $TAG"
    fi
    git -C "$REPO_ROOT" tag -a "$TAG" -m "Release $TAG"
    if [[ "$NO_PUSH" -eq 0 ]]; then
        git -C "$REPO_ROOT" push origin main
        git -C "$REPO_ROOT" push origin "$TAG"
    fi
fi

KDE_STORE_ENV="$REPO_ROOT/.kde-store.env"
if [[ -z "${KDE_STORE_PRODUCT_ID:-}" && -f "$KDE_STORE_ENV" ]]; then
    KDE_STORE_PRODUCT_ID="$(grep -E '^KDE_STORE_PRODUCT_ID=' "$KDE_STORE_ENV" | head -n 1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs || true)"
fi

if [[ -n "${KDE_STORE_PRODUCT_ID:-}" ]]; then
    STORE_URL="https://store.kde.org/p/${KDE_STORE_PRODUCT_ID}/edit"
else
    STORE_URL="https://store.kde.org/product/add"
fi

echo ""
echo "================ KDE Store Upload Checklist ================"
echo "Version:         $NEW_VERSION ($TAG)"
echo "Archive to upload: $TAR_PATH"
echo "GitHub Release:  https://github.com/ReeseJones/desktop_backgrounds/releases/tag/$TAG"
if [[ -n "${KDE_STORE_PRODUCT_ID:-}" ]]; then
    echo "KDE Store Edit:  $STORE_URL"
else
    echo "KDE Store Add:   $STORE_URL"
    echo "Category:        Plasma 6 Wallpaper Plugins"
    echo "License:         GPLv3+"
    echo "Tip: Save 'KDE_STORE_PRODUCT_ID=<your-id>' in $KDE_STORE_ENV after creating the product."
fi
echo "============================================================"

if [[ "$OPEN_STORE" -eq 1 && "$DRY_RUN" -eq 0 ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$STORE_URL" >/dev/null 2>&1 &
fi
