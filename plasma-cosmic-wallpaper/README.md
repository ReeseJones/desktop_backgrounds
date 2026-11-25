# Cosmic Space & Plasma (`com.reesedrjones.cosmicspace`)

A native GPU-accelerated KDE Plasma 6 live wallpaper plugin featuring three procedural GLSL 440 deep-space & plasma shaders rendered directly at your monitor's native resolution (1080p, 1440p, 4K+) with zero pixelation or video compression artifacts.

## Presets

1. **Cosmic Plasma Nebula** — Volumetric domain-warped deep-blue and royal-violet clouds, dark carved dust lanes, sinuous electric-cyan plasma filaments, and a multi-layer pinpoint starfield with diffraction spikes.
2. **Event Horizon Vortex** — Relativistic tilted plasma accretion disk, gravitationally lensed halo arches, razor-sharp photon ring, dark event horizon shadow, and gravitationally deflected stars.
3. **Deep-Space Plasma Aurora** — Darker, desktop-icon-friendly midnight sky with calm pinpoint starlight and four translucent cyan/cobalt/violet plasma aurora curtains.

## Settings (KDE Wallpaper Config)

- **Preset** selector with live 16:9 preview
- **Animation Speed** (`0%–200%`)
- **Star Density** (`20%–200%`)
- **Brightness** (`50%–150%`)
- **Palette Balance** (`Deep Blue / Cyan` ↔ `Balanced` ↔ `Purple / Violet`)
- **Frame Rate** (`30 FPS`, `60 FPS`, or `VSync`)
- **Pause when maximized/fullscreen** (automatically pauses GPU work when a window covers the screen)
- **Right-click Desktop Actions**: *Next Cosmic Preset* and *Pause/Resume Cosmic Animation*

## Build & Install

```bash
./scripts/install.sh
```

Then right-click your desktop → **Desktop and Wallpaper** → **Wallpaper type** → **Cosmic Space & Plasma**.

Or apply it from a terminal in your active Plasma session:

```bash
./scripts/apply.sh --preset 0
```
