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

#### Testing & Screenshot Debugging

Run automated checks (Bash syntax, package XML/JSON, QSB v8 compat, `qmllint`, and GPU offscreen render validation) or capture product/debug screenshots from the repo root:

```bash
# Run full test suite against plasma-cosmic-wallpaper (or --target <dir>)
./scripts/test-wallpaper.sh

# Generate official KDE Store gallery PNGs into dist/screenshots/
./scripts/screenshot.sh --product

# Debug a single shader across multiple timestamps (e.g. 1-hour windup soak) or custom size
./scripts/screenshot.sh --preset 1 --times 18,3600 --size 1920x1080
./scripts/screenshot.sh --suite soak
```

See [docs/TESTING.md](docs/TESTING.md) for the complete debugging cookbook and multi-wallpaper repo contract.

#### Packaging & Publishing (KDE Store / GitHub Releases)

Build a cross-Qt6 KDE Store archive (`dist/com.reesedrjones.cosmicspace-<version>.tar.gz`) or cut a tagged release:

```bash
cd plasma-cosmic-wallpaper
./scripts/package.sh --screenshots
./scripts/release.sh patch --open
```

See [docs/PUBLISHING.md](docs/PUBLISHING.md) for version management and KDE Store publishing steps.

## Architecture & Official Docs

These wallpapers are built with four core KDE Plasma 6 and Qt 6 pieces (pure QML + GLSL shaders, no C++ compilation needed):
- **Plasma 6 `Plasma/Wallpaper` KPackage** (`metadata.json` + `contents/` layout installed via `kpackagetool6`)
- **KConfigXT & `cfg_*` bindings** (`contents/config/main.xml` schema persisted by Plasma and exposed to `main.qml` and `config.qml`)
- **`WallpaperItem` QML API** (`org.kde.plasma.plasmoid` root item with right-click `contextualActions`, `accentColor`, and `org.kde.taskmanager` window observation)
- **Qt 6 `ShaderEffect` + `qsb`** (Vulkan-style GLSL 440 `.frag` sources baked offline into cross-backend `.frag.qsb` bundles for Qt Quick RHI)

See **[docs/KDE_AND_QT.md](docs/KDE_AND_QT.md)** for the full walkthrough (uniform block contract, `cfg_*` binding flow, `plasmashell` reload notes, distro packages) alongside [docs/TESTING.md](docs/TESTING.md) and [docs/PUBLISHING.md](docs/PUBLISHING.md).

**Direct Upstream References:**
- **KDE Plasma 6**: [Plasma Developer Docs](https://develop.kde.org/docs/plasma/) · [`WallpaperItem` API](https://api.kde.org/qml-org-kde-plasma-plasmoid-wallpaperitem.html) · [Configuration (`main.xml` & `cfg_*`)](https://develop.kde.org/docs/plasma/widget/configuration/) · [KConfigXT Guide](https://develop.kde.org/docs/features/configuration/kconfig_xt/) · [Upstream Plasma 6 Wallpapers](https://invent.kde.org/plasma/plasma-workspace/-/tree/master/wallpapers)
- **Qt 6 Shaders & Scene Graph**: [`ShaderEffect` QML Type](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html) · [`qsb` Shader Baker](https://doc.qt.io/qt-6/qtshadertools-qsb.html) · [Qt Quick Scene Graph & RHI](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html)

## Credits & Acknowledgments

Built with AI assistance using classic procedural graphics techniques:
- *Hash without Sine* (`hash12` / `hash22`) by **Dave Hoskins** (MIT License)
- Analytical ACES filmic tone-mapping fit by **Krzysztof Narkowicz**
- Double domain-warped and 3-4-5 rotated-octave FBM techniques popularized by **Inigo Quilez**
- Quintic smoothstep interpolation and ridged multifractal noise (**Ken Perlin** / **F. Kenton Musgrave**)
- Interleaved Gradient Noise dithering by **Jorge Jimenez**
