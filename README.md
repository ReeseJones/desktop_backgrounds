# Desktop Backgrounds

Custom Linux desktop backgrounds and live KDE Plasma 6 shaders.

## Included

### [Cosmic Space & Plasma](plasma-cosmic-wallpaper/README.md) (`com.reesedrjones.cosmicspace`)

Native GPU-accelerated KDE Plasma 6 live wallpaper plugin featuring three modular GLSL 440 space/plasma shaders with an **Auto-Cycle** mode (configurable hold & smooth crossfade timing, `360 s` hold + `3 s` blend by default), shared customizable base color uniforms (`uColorBg`, `uColorPrimary`, `uColorSecondary`, `uColorAccent`), and palette presets in KDE settings:
- **Cosmic Plasma Nebula**
- **Event Horizon Vortex**
- **Deep-Space Plasma Aurora**

#### Quick Build & Install

```bash
cd plasma-cosmic-wallpaper
./scripts/install.sh
```

Then select **Cosmic Space & Plasma** in **Desktop and Wallpaper** settings, or apply it from your Plasma session with:

```bash
./scripts/apply.sh --preset auto
```
