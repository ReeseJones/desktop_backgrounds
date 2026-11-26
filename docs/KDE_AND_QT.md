# KDE Plasma 6 Wallpaper Plugins & Qt 6 Shaders — Architecture & Reference Guide

This guide explains the KDE Plasma 6 plugin framework, Qt 6 QML runtime, and Qt 6 shader pipeline used in this repository, along with links to official upstream documentation.

---

## 1. KDE Plasma 6 Wallpaper Plugins (`Plasma/Wallpaper` KPackages)

A KDE Plasma 6 wallpaper plugin is a declarative **KPackage** (no C++ compilation or CMake plugin build required). Plasma discovers installed user wallpaper plugins under `~/.local/share/plasma/wallpapers/<plugin-id>/` and manages them with `kpackagetool6 -t Plasma/Wallpaper`.

### Package File Map

Inside [`plasma-cosmic-wallpaper/package/`](../plasma-cosmic-wallpaper/package/):

| File | Role in Plasma 6 |
| --- | --- |
| [`metadata.json`](../plasma-cosmic-wallpaper/package/metadata.json) | Declares `"KPackageStructure": "Plasma/Wallpaper"`, `"X-KDE-ParentApp": "org.kde.plasmashell"`, and the `KPlugin` block (`Id`, `Name`, `Version`, `Description`, `License`, `Website`). |
| [`contents/config/main.xml`](../plasma-cosmic-wallpaper/package/contents/config/main.xml) | **KConfigXT** XML schema defining every persistent setting key, type, and default value. Plasma automatically persists these under `[Wallpaper][com.reesedrjones.cosmicspace][General]` in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. |
| [`contents/ui/main.qml`](../plasma-cosmic-wallpaper/package/contents/ui/main.qml) | Wallpaper entry point with a `WallpaperItem` root (`org.kde.plasma.plasmoid`). Reads saved settings from `root.configuration.<Key>` (a `KConfigPropertyMap`), sets `accentColor`, exposes right-click `contextualActions`, and uses `org.kde.taskmanager` `TasksModel` to pause GPU work when a window is maximized or fullscreen. |
| [`contents/ui/config.qml`](../plasma-cosmic-wallpaper/package/contents/ui/config.qml) | Settings UI mounted inside KDE's **Configure Desktop and Wallpaper** dialog. Uses `Kirigami.FormLayout`, `QtQuick.Controls`, and `org.kde.kquickcontrols` `ColorButton`, binding keys to Plasma's **Apply / Reset / Defaults** buttons via `cfg_<Key>` and `cfg_<Key>Default` properties on the root item. |
| [`contents/ui/CosmicShaderView.qml`](../plasma-cosmic-wallpaper/package/contents/ui/CosmicShaderView.qml) | Pure Qt Quick visual item wrapping two layered `ShaderEffect` elements (allowing smooth Auto-Cycle crossfades and instant reuse in standalone preview tools without Plasma). |
| `contents/shaders/*.frag` & `*.frag.qsb` | Vulkan-style GLSL 440 fragment sources (`.frag` in git) compiled into cross-backend Qt Shader Baker bundles (`.frag.qsb` in installed/release packages). |

### How Plasma 6 Binds Configuration

1. **`main.xml` → `main.qml`**: Every `<entry name="Preset" type="Int">` in `main.xml` becomes dynamically readable/writable at runtime as `root.configuration.Preset` on `WallpaperItem` (backed by `KConfigPropertyMap`). Calling `root.configuration.writeConfig()` flushes programmatic changes (such as right-click *Next Cosmic Preset*).
2. **`main.xml` → `config.qml`**: On the root item of `config.qml`, Plasma automatically synchronizes any property named `cfg_<EntryName>` (and `cfg_<EntryName>Default`) with the settings dialog's **Apply**, **Cancel**, and **Defaults** actions. Declaring `property var configDialog`, `property var wallpaperConfiguration`, and `twinFormLayouts: parentLayout` lets `config.qml` integrate cleanly into KDE's appearance form.
3. **`plasmashell` caching gotcha**: Running `plasmashell` caches QML components and `main.xml` KConfigXT schemas in memory. After editing `main.xml`, `config.qml`, or `main.qml` on a live desktop, restart the shell with `systemctl --user restart plasma-plasmashell` (or run `./scripts/install.sh --reload` from `plasma-cosmic-wallpaper/`).

### Official KDE Documentation

- [KDE Plasma Developer Documentation](https://develop.kde.org/docs/plasma/) — Overview of Plasma 6 architecture and plugin types
- [Built-in Plasma 6 Wallpapers (`plasma-workspace`)](https://invent.kde.org/plasma/plasma-workspace/-/tree/master/wallpapers) — Official upstream KDE wallpaper plugins to reference (`org.kde.image`, `org.kde.color`, etc.)
- [`WallpaperItem` QML Type (`org.kde.plasma.plasmoid`)](https://api.kde.org/qml-org-kde-plasma-plasmoid-wallpaperitem.html) — `configuration`, `contextualActions`, `accentColor`, and `loading` API
- [Getting Started: Metadata & Package Setup](https://develop.kde.org/docs/plasma/widget/setup/) — `metadata.json` structure and `kpackagetool6` install flow
- [Widget/Plugin Configuration Guide](https://develop.kde.org/docs/plasma/widget/configuration/) — How `main.xml` schemas and `cfg_*` bindings work
- [Porting to Plasma 6 / KDE Frameworks 6](https://develop.kde.org/docs/plasma/widget/porting_kf6/) — `metadata.desktop` → `metadata.json`, `WallpaperItem`, and Qt 6 QML changes
- [Using KConfigXT (`*.kcfg` / `main.xml`)](https://develop.kde.org/docs/features/configuration/kconfig_xt/) & [`KConfigPropertyMap` API](https://api.kde.org/kconfigpropertymap.html)
- [KPackage Framework API](https://api.kde.org/kpackage-index.html) & [libplasma API](https://api.kde.org/plasma-index.html)
- [Kirigami UI Documentation](https://develop.kde.org/docs/getting-started/kirigami/), [Kirigami API](https://api.kde.org/kirigami-index.html), & [`KQuickControls.ColorButton`](https://api.kde.org/qml-org-kde-kquickcontrols-colorbutton.html)
- [Plasma Desktop Scripting (`qdbus6 ... evaluateScript`)](https://develop.kde.org/docs/plasma/scripting/) — How `scripts/apply.sh` switches wallpaper plugins via D-Bus

---

## 2. Qt 6, QML & the Qt Quick Shader Pipeline

### Why Shaders Are Pre-Compiled with `qsb`

In Qt 5, `ShaderEffect` evaluated inline GLSL strings directly against OpenGL. In **Qt 6**, the Qt Quick scene graph renders through **QRhi** (Qt Rendering Hardware Interface) across OpenGL, Vulkan, Metal, and Direct3D 11/12. Because inline GLSL strings are no longer supported:

1. Fragment shaders are written in **Vulkan-style GLSL 440** (`#version 440`).
2. At build/package time, **`qsb` (Qt Shader Baker)** compiles each `.frag` into SPIR-V and packages transpiled shader variants (`SPIR-V`, `GLSL`, `HLSL`, `MSL`) into a `.frag.qsb` file.
3. QML `ShaderEffect` loads the compiled `.qsb` URL (`fragmentShader: Qt.resolvedUrl("../shaders/cosmic_nebula.frag.qsb")`).

### QML ↔ GLSL Uniform Block Contract

Qt 6 groups built-in item uniforms and custom QML properties into a single `std140` uniform buffer at `binding = 0`. Notice that **`qt_Matrix` and `qt_Opacity` must always appear first**, and every custom QML property on `ShaderEffect` matches the GLSL member name and type:

```qml
// CosmicShaderView.qml
ShaderEffect {
    readonly property real uTime: root.elapsedTime
    readonly property vector2d uResolution: Qt.vector2d(width * root.dpr, height * root.dpr)
    readonly property color uColorBg: root.colorBg
    fragmentShader: Qt.resolvedUrl("../shaders/cosmic_nebula.frag.qsb")
}
```

```glsl
// cosmic_nebula.frag
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    // ...
    vec2 uResolution;
    vec4 uColorBg;
    // ...
};

void main() {
    // ... render RGB color into `col` ...
    fragColor = vec4(col, 1.0) * qt_Opacity; // enables smooth crossfade opacity in QML
}
```

### Cross-Distro `.qsb` Compatibility (`--qsbversion 65`)

Newer Qt releases bump the `.qsb` container format (for example, Qt 6.12's `qsb` emits `QSB_VERSION=9` by default, which older Qt 6.5–6.8 distros cannot read). Running [`scripts/build.sh`](../plasma-cosmic-wallpaper/scripts/build.sh) `--compat` passes `--qsbversion 65` on Qt ≥ 6.6 so the baked shaders emit `QSB_VERSION=8`, compatible across all Qt 6.5–6.12+ Plasma 6 systems.

### Qt 6 Tooling Used in This Repo

- **`qsb`**: Compiles `.frag` → `.frag.qsb` and inspects container headers (`qsb --dump`).
- **`qml6`**: Standalone Qt Quick runtime used by [`scripts/screenshot.sh`](../scripts/screenshot.sh) with `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl` so GPU shaders render offscreen without a desktop session.
- **`qmllint`**: Static QML analyzer checked by [`scripts/test-wallpaper.sh`](../scripts/test-wallpaper.sh). (`main.qml` passes `--missing-property disable` because `KConfigPropertyMap` exposes `main.xml` keys dynamically at runtime.)
- **`FrameAnimation` vs `Timer`**: [`CosmicShaderView.qml`](../plasma-cosmic-wallpaper/package/contents/ui/CosmicShaderView.qml) uses `FrameAnimation` when VSync is selected and a capped `Timer` for `30` / `60 FPS` power-saving limits.

### Official Qt 6 Documentation

- [`ShaderEffect` QML Type](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html) — Uniform block layout, built-in `qt_Matrix`/`qt_Opacity`, and `qsb` usage
- [`qsb` (Qt Shader Baker) Manual](https://doc.qt.io/qt-6/qtshadertools-qsb.html) & [Qt Shader Tools Overview](https://doc.qt.io/qt-6/qtshadertools-overview.html)
- [Qt Quick Scene Graph](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html) & [QRhi Rendering Hardware Interface](https://doc.qt.io/qt-6/qrhi.html)
- [`FrameAnimation` QML Type](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html)
- [`qmllint` Static Analyzer](https://doc.qt.io/qt-6/qtqml-tooling-qmllint.html)
- [Qt QML Overview](https://doc.qt.io/qt-6/qtqml-index.html), [Qt Quick Overview](https://doc.qt.io/qt-6/qtquick-index.html), & [Qt Quick Controls](https://doc.qt.io/qt-6/qtquickcontrols-index.html)

---

## 3. Local Development Packages by Distro

To develop, lint, compile shaders, and install packages locally you only need runtime Qt 6 + KDE CLI tools (no C++ compiler required):

| Distro | Shader Baker (`qsb`) | `qml6` & `qmllint` | KDE `kpackagetool6` & Plasma 6 |
| --- | --- | --- | --- |
| **Arch / CachyOS** | `qt6-shadertools` | `qt6-declarative` | `kpackage` (`plasma-workspace`) |
| **Ubuntu / Debian** | `qt6-shader-baker` | `qml6-module-qtquick` / `qt6-declarative-dev-tools` | `kpackagetool6` (`libkf6package-bin`) |
| **Fedora** | `qt6-qtshadertools-devel` | `qt6-qtdeclarative-devel` | `kf6-kpackage` (`plasma-workspace`) |

---

## Related Guides in This Repo

- [`TESTING.md`](TESTING.md) — Shader debugging, screenshot generation, and automated verification
- [`PUBLISHING.md`](PUBLISHING.md) — Versioning, cross-Qt6 `.tar.gz` packaging, GitHub Releases, and KDE Store upload steps
