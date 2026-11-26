# Repository Agent Guide (`desktop_backgrounds`)

Instructions for coding agents working in this repository.

## Repository Layout

- `plasma-cosmic-wallpaper/` — KDE Plasma 6 wallpaper plugin (`com.reesedrjones.cosmicspace`)
  - `package/metadata.json` — KPackage metadata and `KPlugin.Version`
  - `package/contents/config/main.xml` — KConfigXT persistent settings schema
  - `package/contents/shaders/*.frag` — GLSL 440 fragment shader sources (tracked in Git; compiled `.frag.qsb` files are gitignored)
  - `package/contents/ui/` — QML wallpaper (`main.qml`, `CosmicShaderView.qml`) and settings UI (`config.qml`)
  - `scripts/` — `build.sh`, `install.sh`, `package.sh`, `release.sh`, `apply.sh`, `render_preview.qml`
- `scripts/` — Repo-level tooling targeting any wallpaper subdir via `--target <dir>` (`test-wallpaper.sh`, `screenshot.sh`, `metadata_tool.py`, `verify_renders.py`)
- `docs/` — Architecture and workflow guides ([`KDE_AND_QT.md`](docs/KDE_AND_QT.md), [`TESTING.md`](docs/TESTING.md), [`PUBLISHING.md`](docs/PUBLISHING.md))

## Development & Verification Rules

- **Shaders**: Edit `.frag` sources only (never edit `.qsb` binaries directly). Keep `qt_Matrix` and `qt_Opacity` first in `layout(std140, binding = 0) uniform buf`, and bake cross-Qt6 `.frag.qsb` bundles with `--compat` (`QSB_VERSION <= 8`).
- **Testing**: After shader, QML, or config changes, run `./scripts/test-wallpaper.sh --target plasma-cosmic-wallpaper`. `qmllint` failures or warnings fail Check 4.
- **Visual checks**: Render offscreen GPU PNGs with `./scripts/screenshot.sh` and inspect them directly; clean up temporary preview directories before committing.
- **Live desktop reload**: Do not run `./scripts/install.sh --reload` unless asked, because it restarts the user's running `plasma-plasmashell`.
- **Scripts**: Prefer standalone `.py` or `.sh` files over multi-line inline scripts in shell commands or workflows.

## Release & KDE Store Checklist

Whenever creating a new release version (via `cd plasma-cosmic-wallpaper && ./scripts/release.sh <patch|minor|major>`):

1. Ensure working tree changes are committed first so `release.sh` can bump `KPlugin.Version` in `package/metadata.json`, build `dist/<plugin-id>-<version>.tar.gz` (with `QSB_VERSION <= 8` `.frag.qsb` files) + `.sha256`, commit `Release v<version>`, tag `v<version>`, and push `main` and the tag to GitHub.
2. Because `store.kde.org` (Pling) has no automated upload API, always remind the user to complete **all three** manual updates on the KDE Store product edit page (`https://store.kde.org/p/2382735/edit`, or using `.kde-store.env`):
   1. **Update the file in the store**: Upload `dist/<plugin-id>-<version>.tar.gz` under the **Files** tab.
   2. **Update the version number**: Update the version on the product page / product log to `<version>` so it matches `KPlugin.Version` and KDE's **Get New Plugins…** (`KNewStuff`) detects the update.
   3. **Update the changelog**: Paste a new changelog entry summarizing the changes in `<version>`.
3. Always generate and include a ready-to-paste changelog message in your response summarizing the user-facing changes since the previous release tag (`git log <prev-tag>..v<version>`).

See [`docs/PUBLISHING.md`](docs/PUBLISHING.md), [`docs/TESTING.md`](docs/TESTING.md), and [`docs/KDE_AND_QT.md`](docs/KDE_AND_QT.md) for full details.
