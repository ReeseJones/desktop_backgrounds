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
- **Frame Rate** (`30 FPS`, `60 FPS`, or `VSync`)
- **Pause when maximized/fullscreen** (automatically pauses GPU work when a window covers the screen)
- **Right-click Desktop Actions**: *Next Cosmic Preset* and *Pause/Resume Cosmic Animation*

## Build & Install

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
