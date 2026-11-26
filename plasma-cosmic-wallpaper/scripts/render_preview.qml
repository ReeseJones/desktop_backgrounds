/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Window
import "../package/contents/ui"

Window {
    id: win

    function hasCliArg(flag) {
        const args = Qt.application.arguments;
        for (let i = 0; i < args.length; ++i) {
            if (args[i] === flag) {
                return true;
            }
        }
        return false;
    }

    function cliArg(flag, fallback) {
        const args = Qt.application.arguments;
        for (let i = 0; i < args.length - 1; ++i) {
            if (args[i] === flag) {
                return args[i + 1];
            }
        }
        return fallback;
    }

    function cliInt(flag, fallback) {
        const raw = win.cliArg(flag, "");
        if (raw.length === 0) {
            return fallback;
        }
        const n = parseInt(raw, 10);
        return isNaN(n) ? fallback : n;
    }

    function cliReal(flag, fallback) {
        const raw = win.cliArg(flag, "");
        if (raw.length === 0) {
            return fallback;
        }
        const n = parseFloat(raw);
        return isNaN(n) ? fallback : n;
    }

    function parsePresetValue(raw) {
        if (raw === "auto") {
            return -1;
        }
        const n = parseInt(raw, 10);
        if (isNaN(n)) {
            return -1;
        }
        return Math.max(-1, Math.min(2, n));
    }

    readonly property int renderWidth: Math.max(64, win.cliInt("--width", 1280))
    readonly property int renderHeight: Math.max(64, win.cliInt("--height", 720))

    width: renderWidth
    height: renderHeight
    visible: true
    color: "#030510"
    title: "Cosmic Space & Plasma Preview Renderer"

    readonly property string outDir: win.cliArg("--out-dir", ".")
    readonly property string paletteMode: win.cliArg("--palette", "default")
    readonly property bool hasPresetFlag: win.hasCliArg("--preset")
    readonly property int customPreset: win.parsePresetValue(win.cliArg("--preset", "-1"))
    readonly property real customCycleTime: win.cliReal("--cycle-time", 0.0)
    readonly property string customOutPath: win.cliArg("--out", "")
    readonly property string customBg: win.cliArg("--bg", "#06091c")
    readonly property string customPrimary: win.cliArg("--primary", "#1038b8")
    readonly property string customSecondary: win.cliArg("--secondary", "#8c24e0")
    readonly property string customAccent: win.cliArg("--accent", "#0ee8ff")
    readonly property real brightnessValue: win.cliReal("--brightness", 1.0)
    readonly property real starsValue: win.cliReal("--stars", 1.0)
    readonly property real balanceValue: win.cliReal("--balance", 0.0)
    readonly property real offsetXValue: win.cliReal("--offset-x", 0.0)
    readonly property real offsetYValue: win.cliReal("--offset-y", 0.0)

    readonly property var defaultJobs: [
        { preset: 0, time: 14.5, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "preset0_nebula.png", outPath: "" },
        { preset: 1, time: 18.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "preset1_vortex.png", outPath: "" },
        { preset: 2, time: 12.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "preset2_aurora.png", outPath: "" }
    ]

    readonly property var customJobs: [
        { preset: 0, time: 14.5, cycleTime: 0.0, bg: "#061c17", primary: "#0b7268", secondary: "#1e4fa3", accent: "#3effc8", file: "preset0_emerald.png", outPath: "" },
        { preset: 1, time: 18.0, cycleTime: 0.0, bg: "#1c0713", primary: "#96184a", secondary: "#5b1a99", accent: "#ff9e2c", file: "preset1_crimson.png", outPath: "" },
        { preset: 2, time: 12.0, cycleTime: 0.0, bg: "#06162b", primary: "#0f5298", secondary: "#248ea6", accent: "#6ef7ff", file: "preset2_arctic.png", outPath: "" }
    ]

    readonly property var voidTestJobs: [
        { preset: 0, time: 14.5, cycleTime: 0.0, bg: "#241042", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "voidtest0_violet_nebula.png", outPath: "" },
        { preset: 1, time: 18.0, cycleTime: 0.0, bg: "#2e0d24", primary: "#96184a", secondary: "#5b1a99", accent: "#ff9e2c", file: "voidtest1_plum_vortex.png", outPath: "" },
        { preset: 2, time: 12.0, cycleTime: 0.0, bg: "#0c362e", primary: "#0b7268", secondary: "#1e4fa3", accent: "#3effc8", file: "voidtest2_emerald_aurora.png", outPath: "" }
    ]

    readonly property var blendJobs: [
        { preset: -1, time: 16.0, cycleTime: 361.5, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "blend0to1_nebula_vortex.png", outPath: "" },
        { preset: -1, time: 16.0, cycleTime: 400.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "hold_scene1_vortex.png", outPath: "" },
        { preset: -1, time: 16.0, cycleTime: 724.5, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "blend1to2_vortex_aurora.png", outPath: "" }
    ]

    readonly property var soakJobs: [
        { preset: 0, time: 18.0,   cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "soak_preset0_t18.png", outPath: "" },
        { preset: 0, time: 3600.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "soak_preset0_t3600.png", outPath: "" },
        { preset: 1, time: 18.0,   cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "soak_preset1_t18.png", outPath: "" },
        { preset: 1, time: 3600.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "soak_preset1_t3600.png", outPath: "" },
        { preset: 2, time: 18.0,   cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "soak_preset2_t18.png", outPath: "" },
        { preset: 2, time: 3600.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "soak_preset2_t3600.png", outPath: "" }
    ]

    function buildAdHocJobs() {
        const label = (win.customPreset < 0) ? "auto" : String(win.customPreset);
        const rawTimes = win.cliArg("--times", "");
        let times = [];
        if (rawTimes.length > 0) {
            const parts = rawTimes.split(",");
            for (let i = 0; i < parts.length; ++i) {
                const trimmed = parts[i].trim();
                const parsed = parseFloat(trimmed);
                if (!isNaN(parsed)) {
                    times.push(parsed);
                }
            }
        }
        if (times.length === 0) {
            times.push(win.cliReal("--time", 18.0));
        }

        const outJobs = [];
        for (let i = 0; i < times.length; ++i) {
            const tVal = times[i];
            const tLabel = String(tVal);
            const directOut = (times.length === 1 && win.customOutPath.length > 0) ? win.customOutPath : "";
            outJobs.push({
                preset: win.customPreset,
                time: tVal,
                cycleTime: win.customCycleTime,
                bg: win.customBg,
                primary: win.customPrimary,
                secondary: win.customSecondary,
                accent: win.customAccent,
                file: "debug_preset" + label + "_t" + tLabel + ".png",
                outPath: directOut
            });
        }
        return outJobs;
    }

    readonly property var jobs: {
        if (win.hasPresetFlag) {
            return win.buildAdHocJobs();
        }
        if (win.paletteMode === "custom") {
            return win.customJobs;
        }
        if (win.paletteMode === "product") {
            return win.defaultJobs.concat(win.customJobs);
        }
        if (win.paletteMode === "voidtest") {
            return win.voidTestJobs;
        }
        if (win.paletteMode === "blend") {
            return win.blendJobs;
        }
        if (win.paletteMode === "soak") {
            return win.soakJobs;
        }
        if (win.paletteMode === "quick") {
            return win.defaultJobs.concat(win.soakJobs);
        }
        if (win.paletteMode === "all") {
            return win.defaultJobs.concat(win.customJobs).concat(win.voidTestJobs).concat(win.blendJobs).concat(win.soakJobs);
        }
        return win.defaultJobs;
    }
    property int currentStep: 0

    CosmicShaderView {
        id: shaderView
        anchors.fill: parent
        preset: win.jobs[win.currentStep].preset
        initialTime: win.jobs[win.currentStep].time
        initialCycleTime: win.jobs[win.currentStep].cycleTime
        cycleHoldSeconds: 360.0
        cycleBlendSeconds: 3.0
        colorBg: win.jobs[win.currentStep].bg
        colorPrimary: win.jobs[win.currentStep].primary
        colorSecondary: win.jobs[win.currentStep].secondary
        colorAccent: win.jobs[win.currentStep].accent
        speed: 0.75
        starDensity: win.starsValue
        brightness: win.brightnessValue
        colorBalance: win.balanceValue
        offsetX: win.offsetXValue
        offsetY: win.offsetYValue
        fpsLimit: 60
        paused: true
    }

    Timer {
        id: captureTimer
        interval: 250
        repeat: false
        onTriggered: {
            const job = win.jobs[win.currentStep];
            const path = job.outPath.length > 0 ? job.outPath : (win.outDir + "/" + job.file);
            shaderView.grabToImage(function(result) {
                const ok = result.saveToFile(path);
                console.log((ok ? "Saved: " : "Failed to save: ") + path);
                if (!ok) {
                    Qt.exit(1);
                    return;
                }
                if (win.currentStep + 1 < win.jobs.length) {
                    win.currentStep += 1;
                    captureTimer.restart();
                } else {
                    Qt.quit();
                }
            }, Qt.size(win.renderWidth, win.renderHeight));
        }
    }

    Timer {
        interval: 45000
        running: true
        repeat: false
        onTriggered: {
            console.error("Preview render timed out.");
            Qt.exit(1);
        }
    }

    Component.onCompleted: {
        captureTimer.start();
    }
}
