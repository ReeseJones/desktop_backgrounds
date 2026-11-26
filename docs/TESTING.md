# Testing, Screenshot Generation & Shader Debugging

This repository includes repo-level CLI tooling so both humans and coding agents can compile, lint, render on the real GPU offscreen, and visually inspect KDE Plasma 6 wallpaper shaders without touching or restarting your live desktop session.

All top-level tools target any wallpaper subdirectory via `--target <dir>` (defaulting to `plasma-cosmic-wallpaper`).

---

## Quick Validation (`scripts/test-wallpaper.sh`)

Run the full validation pass from the repository root:

```bash
./scripts/test-wallpaper.sh
```

What it checks:
1. **Script syntax** (`bash -n` across `scripts/*.sh` / `<target>/scripts/*.sh`, and `python3 -m ast` across `scripts/*.py` / `<target>/scripts/*.py`)
2. **Package schema** (`package/metadata.json` `X.Y.Z` version + `contents/config/main.xml` XML parse)
3. **Shader baking & compatibility** (`build.sh --compat` + verifies every `.frag.qsb` reports `QSB_VERSION <= 8`)
4. **QML lint** (`qmllint` on all UI and preview QML files)
5. **Offscreen GPU render verification** (`scripts/screenshot.sh --suite quick`) — renders PNGs on the GPU and validates `IHDR` resolution plus non-blank file size

Useful variants:

```bash
# Full matrix: default, custom themes, voidtest, blend midpoints, and 1-hour soak renders
./scripts/test-wallpaper.sh --suite full

# 1-hour windup regression soak only (t = 18 s and t = 3600 s across all shaders)
./scripts/test-wallpaper.sh --suite soak

# Static/build checks only (CI or headless CPU-only hosts without a GPU driver)
./scripts/test-wallpaper.sh --no-render

# Target another wallpaper directory in this repo
./scripts/test-wallpaper.sh --target another-wallpaper-dir
```

Rendered test images default to `<target>/previews/test-run/` (gitignored).

---

## Generating Official KDE Store Product Screenshots

To generate the 6 official `1280×720` gallery PNGs into `dist/screenshots/` (three default-palette scenes plus three custom-themed variants):

```bash
./scripts/screenshot.sh --product
```

Or build the release archive and product gallery together:

```bash
cd plasma-cosmic-wallpaper
./scripts/package.sh --screenshots
```

Both commands produce the same verified PNGs in `dist/screenshots/`:
- `preset0_nebula.png`, `preset1_vortex.png`, `preset2_aurora.png`
- `preset0_emerald.png`, `preset1_crimson.png`, `preset2_arctic.png`

---

## Shader Debugging Cookbook (`scripts/screenshot.sh`)

`scripts/screenshot.sh` automatically compiles updated `.frag` shaders via `build.sh` (skip with `--no-build`), configures the offscreen GPU scenegraph, and saves PNGs into `<target>/previews/` by default (gitignored).

### 1. Check for Spiral Windup or Time Precision Bugs
Compare `t = 18 s` against `t = 3600 s` (1 hour of desktop runtime) in one command:

```bash
./scripts/screenshot.sh --preset 1 --times 18,3600
```

Or run the `soak` batch across all three shaders:

```bash
./scripts/screenshot.sh --suite soak
```

### 2. Test Native Monitor Resolutions (1080p / 1440p / 4K)

```bash
./scripts/screenshot.sh --preset 0 --time 14.5 --size 2560x1440
./scripts/screenshot.sh --preset 1 --time 18.0 --size 3840x2160
```

### 3. Test Auto-Cycle Transitions (`--preset auto`)
By default, Auto-Cycle holds each scene for `360 s` and blends over `3 s`:
- `0–360 s` = Scene 0 hold, `360–363 s` = Scene 0 → Scene 1 crossfade (`361.5` = exact 50% blend)
- `723–726 s` = Scene 1 → Scene 2 crossfade (`724.5` = exact 50% blend)

```bash
./scripts/screenshot.sh --preset auto --cycle-time 361.5 --out plasma-cosmic-wallpaper/previews/blend_0_to_1.png
```

### 4. Test Custom Base Colors & Shader Uniforms
Override `uColorBg`, `uColorPrimary`, `uColorSecondary`, `uColorAccent`, brightness, star density, or palette balance:

```bash
./scripts/screenshot.sh \
  --preset 2 --time 12 \
  --bg "#0c362e" --primary "#0b7268" --secondary "#1e4fa3" --accent "#3effc8" \
  --brightness 1.1 --stars 1.4 --balance -0.25 \
  --out plasma-cosmic-wallpaper/previews/emerald_aurora_test.png
```

### 5. Run Diagnostic Suites
- `--suite default` — 3 default-palette presets
- `--suite custom` — 3 custom-palette theme presets
- `--suite product` — `default` + `custom` (6 official store screenshots)
- `--suite voidtest` — lifted Space Void backgrounds (`#241042`, `#2e0d24`, `#0c362e`) to verify `uColorBg` isn't crushed to black
- `--suite blend` — Auto-Cycle crossfade midpoints (`361.5 s`, `400.0 s`, `724.5 s`)
- `--suite soak` — `t = 18 s` vs `t = 3600 s` across presets 0–2
- `--suite quick` — `default` + `soak`
- `--suite all` — all of the above

---

## How Headless GPU Rendering Works

Qt Quick loads pre-compiled `.frag.qsb` shader bundles, not raw `.frag` text—remember to recompile shaders whenever editing GLSL (handled automatically by `screenshot.sh` unless `--no-build` is passed).

Plain `QT_QPA_PLATFORM=offscreen` silently falls back to Qt's **software** scenegraph backend, which skips `ShaderEffect` and outputs blank ~4 KB PNGs. To run the real GPU shader pipeline offscreen, `screenshot.sh` invokes `qml6` with:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl
```

*(Override `openGL` with `COSMIC_RHI_BACKEND=vulkan ./scripts/screenshot.sh ...` if needed.)* After rendering, `screenshot.sh` reads every saved PNG header (`IHDR`) to confirm the exact requested `WxH` dimensions and rejects trivially small (`< 20 KB`) blank/software-fallback renders.

---

## Visual Inspection Checklist (Humans & Agents)

When inspecting rendered PNGs after shader or QML edits, verify:
- **Zero spiral windup / moiré**: compare `soak_preset*_t18.png` and `soak_preset*_t3600.png` side-by-side—structures must remain clean and organic at 1 hour with no tight concentric aliasing stripes.
- **No seam artifacts**: radial effects evaluated in Cartesian space should show zero horizontal/vertical `atan` seam lines.
- **Layering & occlusion**: foreground elements (e.g., `event_horizon` disk sweeping across the shadow edge and photon ring) blend cleanly without sharp stepping.
- **Pinpoint starfield**: dense crisp sub-pixel/1-pixel star cores with controlled diffraction spikes only on brightest stars (no oversized blurry discs).
- **Space Void (`uColorBg`) fidelity**: in `--suite voidtest`, the dark corners and outer backdrop visibly reflect the chosen `#241042` / `#2e0d24` / `#0c362e` void tint rather than collapsing to pitch black.
- **Smooth dark gradients**: dithering eliminates visible 8-bit contour rings across outer nebula/halo falloffs.
- **Qt 6 portability**: `test-wallpaper.sh` Check 3 confirms every `.frag.qsb` uses `QSB_VERSION <= 8`.

---

## Multi-Wallpaper Repository Contract

Any new KDE Plasma wallpaper added under `<repo-root>/<wallpaper-dir>/` works automatically with `./scripts/screenshot.sh --target <wallpaper-dir>` and `./scripts/test-wallpaper.sh --target <wallpaper-dir>` when it follows this layout:

- `package/metadata.json` (`KPackageStructure: "Plasma/Wallpaper"`, `X-KDE-ParentApp: "org.kde.plasmashell"`, `KPlugin.Id`, `KPlugin.Name`, `KPlugin.Version`)
- `package/contents/config/main.xml`
- `package/contents/shaders/*.frag` and `package/contents/ui/*.qml`
- `scripts/build.sh` (accepting optional `--compat`)
- `scripts/render_preview.qml` (accepting `--out-dir`, `--palette`, `--width`, `--height`, plus `--preset`, `--time`, `--times`, `--out`, etc., and printing `Saved: <path>` per generated PNG)
