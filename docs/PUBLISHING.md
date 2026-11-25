# Publishing & Version Management for the KDE Store

## How KDE Store Version Detection Works

When users install or check for updates via **Desktop and Wallpaper → Get New Plugins…** (`KNewStuff`), KDE compares:

- The local `KPlugin.Version` inside `~/.local/share/plasma/wallpapers/com.reesedrjones.cosmicspace/metadata.json`
- The remote `Version` of the latest upload on [store.kde.org](https://store.kde.org/) (linked by your unchanging `KPlugin.Id`: `com.reesedrjones.cosmicspace`)

Using strictly increasing `X.Y.Z` versions (`1.0.0` → `1.0.1` → `1.1.0`) in [`metadata.json`](../plasma-cosmic-wallpaper/package/metadata.json) ensures Plasma always recognizes when a newer release is available. You don't need backward-compatibility shims between config versions, though keeping `KPlugin.Id` constant preserves users' update link.

## Why Release Archives Bundle Pre-Baked `.frag.qsb` Shaders

- Git keeps only human-readable `.frag` GLSL sources (`*.qsb` is gitignored).
- When someone installs from the KDE Store, Plasma extracts the `.tar.gz` directly without compiling anything.
- [`scripts/package.sh`](../plasma-cosmic-wallpaper/scripts/package.sh) runs [`scripts/build.sh --compat`](../plasma-cosmic-wallpaper/scripts/build.sh) so `.frag.qsb` binaries are baked with `--qsbversion 65` (`QSB_VERSION=8`) on Qt ≥ 6.6, making a single archive compatible across KDE Plasma 6 distros (Qt 6.5 through 6.12+).

## Why Uploading to the KDE Store Has One Manual Step

`store.kde.org` / OpenDesktop (Pling) does not provide official developer API tokens or a supported CLI/GitHub Action for creating products or uploading files—write requests on Pling are bound to browser session cookies and CSRF checks.

To keep publishing fast and foolproof:
1. **Local/CI packaging + GitHub Releases** are 100% automated via [`scripts/release.sh`](../plasma-cosmic-wallpaper/scripts/release.sh) and [`.github/workflows/release.yml`](../.github/workflows/release.yml).
2. **KDE Store** only needs a quick drag-and-drop upload of the generated `.tar.gz` on your product page.

---

## One-Time Setup on `store.kde.org`

1. Package the archive and render store gallery screenshots:
   ```bash
   cd plasma-cosmic-wallpaper
   ./scripts/package.sh --screenshots
   ```
   This builds:
   - `dist/com.reesedrjones.cosmicspace-1.0.0.tar.gz`
   - `dist/screenshots/*.png` (6 crisp 1280×720 screenshots of all presets and custom color themes)
2. Sign in to [store.kde.org](https://store.kde.org/) (or opendesktop.org) with your GitHub account and click **Add Product**:
   - **Name**: `Cosmic Space & Plasma`
   - **Category**: **Plasma 6 Wallpaper Plugins**
   - **License**: **GPLv3+**
   - **Source / Homepage**: `https://github.com/ReeseJones/desktop_backgrounds`
   - **Images**: upload PNGs from `dist/screenshots/`
   - **Files**: upload `dist/com.reesedrjones.cosmicspace-1.0.0.tar.gz` (and optionally set External Link to `https://github.com/ReeseJones/desktop_backgrounds/releases/latest/download/com.reesedrjones.cosmicspace-latest.tar.gz` if you prefer GitHub-hosted downloads, though direct file upload guarantees `metadata.json` version inspection by Pling).
3. Copy your numeric product ID from the published URL (`https://store.kde.org/p/<ID>/`) and save it locally (gitignored):
   ```bash
   echo 'KDE_STORE_PRODUCT_ID=<ID>' > .kde-store.env
   ```

---

## Releasing Future Updates

1. Commit your code changes on `main`.
2. Run the release helper:
   ```bash
   cd plasma-cosmic-wallpaper
   ./scripts/release.sh patch --open
   ```
   *(Supports `patch`, `minor`, `major`, `same`, or an explicit `X.Y.Z`, plus optional `--screenshots`, `--dry-run`, and `--no-push`.)*
3. What `release.sh` does automatically:
   - Updates `KPlugin.Version` in `package/metadata.json`
   - Builds and verifies `dist/com.reesedrjones.cosmicspace-<version>.tar.gz` + `.sha256`
   - Commits `"Release v<version>"`, creates annotated tag `v<version>`, and pushes to GitHub (triggering GitHub Actions to publish the GitHub Release)
   - Opens your KDE Store edit page (`--open`) and prints the exact archive path to upload in the **Files** tab.
