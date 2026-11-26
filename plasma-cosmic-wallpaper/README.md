# Cosmic Space & Plasma (`com.reesedrjones.cosmicspace`)

A native GPU-accelerated KDE Plasma 6 live wallpaper plugin featuring three procedural GLSL 440 deep-space & plasma shaders rendered directly at your monitor's native resolution (1080p, 1440p, 4K+) with zero pixelation or video compression artifacts.

## Presets & Auto-Cycle

- **Auto-Cycle (All Scenes)** *(default)* — Holds 100% on each shader for **Hold Duration** (`360 s` / `6m` default) and smoothly crossfades over **Transition Blend** (`3 s` default) into the next scene using modular two-layer Qt Quick `ShaderEffect` compositing (with zero extra GPU shader cost during the hold period).
1. **Cosmic Plasma Nebula** — Volumetric domain-warped deep-blue and royal-violet clouds, dark carved dust lanes, sinuous electric-cyan plasma filaments, and a multi-layer pinpoint starfield with diffraction spikes.
2. **Event Horizon Vortex** — Relativistic tilted plasma accretion disk, gravitationally lensed halo arches, razor-sharp photon ring, dark event horizon shadow, and gravitationally deflected stars.
3. **Deep-Space Plasma Aurora** — Darker, desktop-icon-friendly midnight sky with calm pinpoint starlight and four translucent cyan/cobalt/violet plasma aurora curtains.

## Settings (KDE Wallpaper Config)

- **Preset** selector with live 16:9 preview (*Auto-Cycle* or any individual shader)
- **Hold Duration** (`5–3600 s`, `360 s` default) and **Transition Blend** (`0–30 s`, `3 s` default) — unscaled wall-clock cycle timing independent of animation speed
- **Color Palette** quick presets (*Cosmic Deep Blue*, *Ultraviolet Nebula*, *Emerald Abyss*, *Crimson Event*, *Arctic Aurora*, *Custom*)
- **Base Colors** (shared `uColorBg`, `uColorPrimary`, `uColorSecondary`, `uColorAccent` uniforms across all three shaders, configurable via KDE color pickers):
  - **Space Void** (`#06091c` default)
  - **Primary Glow** (`#1038b8` default)
  - **Secondary Glow** (`#8c24e0` default)
  - **Plasma Highlight** (`#0ee8ff` default)
- **Animation Speed** (`0%–200%`)
- **Star Density** (`20%–200%`)
- **Brightness** (`50%–150%`)
- **Palette Balance** (`Primary / Highlight` ↔ `Balanced` ↔ `Secondary`)
- **Center Offset** (`-150%` to `+150%` X/Y sliders, or click-and-drag directly on the live preview to reposition the scene center)
- **Frame Rate** (`30 FPS`, `60 FPS`, or `VSync`)
- **Pause when maximized/fullscreen** (automatically pauses GPU work when a window covers the screen)
- **Right-click Desktop Actions**: *Next Cosmic Preset* and *Pause/Resume Cosmic Animation*

## Install

- **KDE Store**: [Cosmic Space & Plasma](https://store.kde.org/p/2382735/) — or install inside Plasma via **Desktop and Wallpaper → Get New Plugins…**.
- **From source**:

```bash
./scripts/install.sh
```

If upgrading while the wallpaper is already running in Plasma, pass `--reload` (or run `systemctl --user restart plasma-plasmashell`) so KDE reloads updated QML and KConfigXT schema keys immediately:

```bash
./scripts/install.sh --reload
```

Then right-click your desktop → **Desktop and Wallpaper** → **Wallpaper type** → **Cosmic Space & Plasma**.

Or apply it from a terminal in your active Plasma session:

```bash
./scripts/apply.sh --preset auto
```

## Testing & Screenshot Debugging

Validate shaders, QML, and GPU offscreen renders from the repository root using `--target`:

```bash
# Syntax, metadata/XML, QSB v8 compatibility, qmllint, and offscreen GPU renders
../scripts/test-wallpaper.sh --target plasma-cosmic-wallpaper

# Generate the 6 official 1280x720 KDE Store gallery PNGs into ../dist/screenshots/
../scripts/screenshot.sh --product

# Debug shader behavior (1-hour time soak, custom resolution, or Auto-Cycle midpoint blend)
../scripts/screenshot.sh --suite soak
../scripts/screenshot.sh --preset 1 --times 18,3600 --size 1920x1080
../scripts/screenshot.sh --preset auto --cycle-time 361.5 --out previews/blend.png
```

See [../docs/TESTING.md](../docs/TESTING.md) for all suite presets (`default`, `custom`, `voidtest`, `blend`, `soak`, `quick`, `product`, `all`), uniform override flags, and why offscreen GPU rendering uses Qt Quick RHI (`QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl`).

## Packaging & Releases

- Build a cross-distro KDE Store archive (pre-baked with QSB v8 for Qt 6.5–6.12+) and optional gallery screenshots:
  ```bash
  ./scripts/package.sh --screenshots
  ```
- Bump `metadata.json` version, package, tag, push to GitHub Releases CI, and open the KDE Store upload page:
  ```bash
  ./scripts/release.sh patch --open
  ```

See [../docs/PUBLISHING.md](../docs/PUBLISHING.md) for details.

## Architecture & References

For a guided explanation of how `Plasma/Wallpaper` KPackages, KConfigXT (`main.xml` + `cfg_*`), `WallpaperItem`, and Qt 6's `ShaderEffect` + `qsb` pipeline fit together, see **[../docs/KDE_AND_QT.md](../docs/KDE_AND_QT.md)**.

Key official upstream docs:
- **KDE Plasma 6**: [`WallpaperItem` API](https://api.kde.org/qml-org-kde-plasma-plasmoid-wallpaperitem.html) · [Plasma Configuration & KConfigXT](https://develop.kde.org/docs/plasma/widget/configuration/) · [Upstream Wallpapers](https://invent.kde.org/plasma/plasma-workspace/-/tree/master/wallpapers)
- **Qt 6**: [`ShaderEffect` QML Type](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html) · [`qsb` (Qt Shader Baker)](https://doc.qt.io/qt-6/qtshadertools-qsb.html) · [Qt Quick Scene Graph](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html)

## Credits & Acknowledgments

Built with AI assistance using classic procedural graphics techniques:
- *Hash without Sine* (`hash12` / `hash22`) by **Dave Hoskins** (MIT License)
- Analytical ACES filmic tone-mapping fit by **Krzysztof Narkowicz**
- Double domain-warped and 3-4-5 rotated-octave FBM techniques popularized by **Inigo Quilez**
- Quintic smoothstep interpolation and ridged multifractal noise (**Ken Perlin** / **F. Kenton Musgrave**)
- Interleaved Gradient Noise dithering by **Jorge Jimenez**
