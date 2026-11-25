# Desktop Backgrounds

Custom Linux desktop backgrounds and live KDE Plasma 6 shaders.

## Included

### [Cosmic Space & Plasma](plasma-cosmic-wallpaper/README.md) (`com.reesedrjones.cosmicspace`)

Native GPU-accelerated KDE Plasma 6 live wallpaper plugin featuring three modular GLSL 440 space/plasma shaders with an **Auto-Cycle** mode (configurable hold & smooth crossfade timing, `360 s` hold + `3 s` blend by default), shared customizable base color uniforms (`uColorBg`, `uColorPrimary`, `uColorSecondary`, `uColorAccent`), and palette presets in KDE settings:
- **Cosmic Plasma Nebula**
- **Event Horizon Vortex**
- **Deep-Space Plasma Aurora**

#### Quick Build & Install

- **KDE Store**: [Cosmic Space & Plasma](https://store.kde.org/p/2382735/) (or install inside Plasma via **Desktop and Wallpaper → Get New Plugins…**)
- **From source**:

```bash
cd plasma-cosmic-wallpaper
./scripts/install.sh
```

Then select **Cosmic Space & Plasma** in **Desktop and Wallpaper** settings, or apply it from your Plasma session with:

```bash
./scripts/apply.sh --preset auto
```

#### Packaging & Publishing (KDE Store / GitHub Releases)

Build a cross-Qt6 KDE Store archive (`dist/com.reesedrjones.cosmicspace-<version>.tar.gz`) or cut a tagged release:

```bash
cd plasma-cosmic-wallpaper
./scripts/package.sh --screenshots
./scripts/release.sh patch --open
```

See [docs/PUBLISHING.md](docs/PUBLISHING.md) for version management and KDE Store publishing steps.

## Credits & Acknowledgments

Built with AI assistance using classic procedural graphics techniques:
- *Hash without Sine* (`hash12` / `hash22`) by **Dave Hoskins** (MIT License)
- Analytical ACES filmic tone-mapping fit by **Krzysztof Narkowicz**
- Double domain-warped and 3-4-5 rotated-octave FBM techniques popularized by **Inigo Quilez**
- Quintic smoothstep interpolation and ridged multifractal noise (**Ken Perlin** / **F. Kenton Musgrave**)
