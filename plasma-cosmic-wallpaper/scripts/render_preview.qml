/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Window
import "../package/contents/ui"

Window {
    id: win
    width: 1280
    height: 720
    visible: true
    color: "#030510"
    title: "Cosmic Space & Plasma Preview Renderer"

    property string outDir: {
        const args = Qt.application.arguments;
        for (let i = 0; i < args.length - 1; ++i) {
            if (args[i] === "--out-dir") {
                return args[i + 1];
            }
        }
        return ".";
    }

    property string paletteMode: {
        const args = Qt.application.arguments;
        for (let i = 0; i < args.length - 1; ++i) {
            if (args[i] === "--palette") {
                return args[i + 1];
            }
        }
        return "default";
    }

    readonly property var defaultJobs: [
        { preset: 0, time: 14.5, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "preset0_nebula.png" },
        { preset: 1, time: 18.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "preset1_vortex.png" },
        { preset: 2, time: 12.0, cycleTime: 0.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "preset2_aurora.png" }
    ]

    readonly property var customJobs: [
        { preset: 0, time: 14.5, cycleTime: 0.0, bg: "#061c17", primary: "#0b7268", secondary: "#1e4fa3", accent: "#3effc8", file: "preset0_emerald.png" },
        { preset: 1, time: 18.0, cycleTime: 0.0, bg: "#1c0713", primary: "#96184a", secondary: "#5b1a99", accent: "#ff9e2c", file: "preset1_crimson.png" },
        { preset: 2, time: 12.0, cycleTime: 0.0, bg: "#06162b", primary: "#0f5298", secondary: "#248ea6", accent: "#6ef7ff", file: "preset2_arctic.png" }
    ]

    readonly property var voidTestJobs: [
        { preset: 0, time: 14.5, cycleTime: 0.0, bg: "#241042", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "voidtest0_violet_nebula.png" },
        { preset: 1, time: 18.0, cycleTime: 0.0, bg: "#2e0d24", primary: "#96184a", secondary: "#5b1a99", accent: "#ff9e2c", file: "voidtest1_plum_vortex.png" },
        { preset: 2, time: 12.0, cycleTime: 0.0, bg: "#0c362e", primary: "#0b7268", secondary: "#1e4fa3", accent: "#3effc8", file: "voidtest2_emerald_aurora.png" }
    ]

    readonly property var blendJobs: [
        { preset: -1, time: 16.0, cycleTime: 361.5, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "blend0to1_nebula_vortex.png" },
        { preset: -1, time: 16.0, cycleTime: 400.0, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "hold_scene1_vortex.png" },
        { preset: -1, time: 16.0, cycleTime: 724.5, bg: "#06091c", primary: "#1038b8", secondary: "#8c24e0", accent: "#0ee8ff", file: "blend1to2_vortex_aurora.png" }
    ]

    readonly property var jobs: {
        if (paletteMode === "custom") {
            return customJobs;
        }
        if (paletteMode === "voidtest") {
            return voidTestJobs;
        }
        if (paletteMode === "blend") {
            return blendJobs;
        }
        if (paletteMode === "all") {
            return defaultJobs.concat(customJobs).concat(voidTestJobs).concat(blendJobs);
        }
        return defaultJobs;
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
        starDensity: 1.0
        brightness: 1.0
        colorBalance: 0.0
        fpsLimit: 60
        paused: true
    }

    Timer {
        id: captureTimer
        interval: 250
        repeat: false
        onTriggered: {
            const job = win.jobs[win.currentStep];
            const path = win.outDir + "/" + job.file;
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
            }, Qt.size(win.width, win.height));
        }
    }

    Timer {
        interval: 15000
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
