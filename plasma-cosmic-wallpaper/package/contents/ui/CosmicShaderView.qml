/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick

Item {
    id: root

    property int preset: -1
    property real speed: 0.75
    property real starDensity: 1.0
    property real brightness: 1.0
    property real colorBalance: 0.0
    property real offsetX: 0.0
    property real offsetY: 0.0
    property color colorBg: "#06091c"
    property color colorPrimary: "#1038b8"
    property color colorSecondary: "#8c24e0"
    property color colorAccent: "#0ee8ff"
    property int fpsLimit: 60
    property bool paused: false
    property real initialTime: 0.0
    property real elapsedTime: initialTime
    property real cycleHoldSeconds: 360.0
    property real cycleBlendSeconds: 3.0
    property real initialCycleTime: 0.0
    property real cycleClock: initialCycleTime

    readonly property var shaderUrls: [
        Qt.resolvedUrl("../shaders/cosmic_nebula.frag.qsb"),
        Qt.resolvedUrl("../shaders/event_horizon.frag.qsb"),
        Qt.resolvedUrl("../shaders/deep_aurora.frag.qsb")
    ]

    readonly property real dpr: (Screen.devicePixelRatio > 0) ? Screen.devicePixelRatio : 1.0
    readonly property bool autoCycle: preset < 0
    readonly property real slotHold: Math.max(1.0, cycleHoldSeconds)
    readonly property real slotBlend: Math.max(0.0, cycleBlendSeconds)
    readonly property real slotDuration: slotHold + slotBlend
    readonly property real clampedCycleClock: Math.max(0.0, cycleClock)
    readonly property int cycleSlot: Math.floor(clampedCycleClock / slotDuration)
    readonly property real inSlot: clampedCycleClock - cycleSlot * slotDuration
    readonly property int autoBaseIndex: cycleSlot % shaderUrls.length
    readonly property int autoNextIndex: (autoBaseIndex + 1) % shaderUrls.length
    readonly property real autoRawBlend: (slotBlend > 0.001 && inSlot >= slotHold)
                                         ? Math.min(1.0, Math.max(0.0, (inSlot - slotHold) / slotBlend))
                                         : 0.0
    readonly property real autoSmoothBlend: autoRawBlend * autoRawBlend * (3.0 - 2.0 * autoRawBlend)

    property int manualBaseIndex: 0
    property int manualNextIndex: 0
    property real manualBlend: 0.0
    property bool _initialized: false
    property bool _wasAuto: preset < 0

    readonly property int activeBaseIndex: autoCycle ? autoBaseIndex : manualBaseIndex
    readonly property int activeNextIndex: autoCycle ? autoNextIndex : manualNextIndex
    readonly property real activeBlend: autoCycle ? autoSmoothBlend : manualBlend

    readonly property bool isTransitioning: activeBlend > 0.0005
    readonly property bool needsHighFps: visible && !paused && (speed > 0.001 || isTransitioning)
    readonly property bool needsLowFpsCycleTick: visible && !paused && autoCycle && !needsHighFps

    function clampSceneIndex(idx) {
        return Math.max(0, Math.min(shaderUrls.length - 1, idx));
    }

    function triggerNextCycleScene() {
        if (!autoCycle) {
            return;
        }
        if (inSlot < slotHold) {
            cycleClock = cycleSlot * slotDuration + slotHold;
        }
    }

    function advanceTime(dt) {
        elapsedTime += dt * speed;
        if (autoCycle) {
            cycleClock += dt;
        }
    }

    onInitialTimeChanged: {
        elapsedTime = initialTime;
    }

    onInitialCycleTimeChanged: {
        cycleClock = initialCycleTime;
    }

    onPausedChanged: {
        if (paused && manualFadeAnim.running) {
            manualFadeAnim.stop();
            manualBaseIndex = manualNextIndex;
            manualBlend = 0.0;
        }
    }

    onPresetChanged: {
        if (!_initialized) {
            manualBaseIndex = clampSceneIndex(preset);
            manualNextIndex = manualBaseIndex;
            manualBlend = 0.0;
            _wasAuto = autoCycle;
            return;
        }

        if (autoCycle) {
            manualFadeAnim.stop();
            if (!_wasAuto) {
                cycleClock = manualBaseIndex * slotDuration;
            }
            manualBlend = 0.0;
            _wasAuto = true;
            return;
        }

        const targetIdx = clampSceneIndex(preset);
        const startIdx = _wasAuto
                         ? (autoSmoothBlend >= 0.5 ? autoNextIndex : autoBaseIndex)
                         : manualBaseIndex;
        _wasAuto = false;

        if (!root.paused && targetIdx !== startIdx && slotBlend > 0.001) {
            manualFadeAnim.stop();
            manualBaseIndex = startIdx;
            manualNextIndex = targetIdx;
            manualBlend = 0.0;
            manualFadeAnim.duration = Math.max(50, Math.round(slotBlend * 1000));
            manualFadeAnim.start();
        } else {
            manualFadeAnim.stop();
            manualBaseIndex = targetIdx;
            manualNextIndex = targetIdx;
            manualBlend = 0.0;
        }
    }

    Component.onCompleted: {
        manualBaseIndex = clampSceneIndex(preset);
        manualNextIndex = manualBaseIndex;
        manualBlend = 0.0;
        _wasAuto = autoCycle;
        _initialized = true;
    }

    NumberAnimation {
        id: manualFadeAnim
        target: root
        property: "manualBlend"
        from: 0.0
        to: 1.0
        easing.type: Easing.InOutSine
        onFinished: {
            root.manualBaseIndex = root.manualNextIndex;
            root.manualBlend = 0.0;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.colorBg
    }

    ShaderEffect {
        id: baseShader
        anchors.fill: parent
        supportsAtlasTextures: false

        readonly property real uTime: root.elapsedTime
        readonly property real uBrightness: root.brightness
        readonly property real uStarDensity: root.starDensity
        readonly property real uColorBalance: root.colorBalance
        readonly property vector2d uResolution: Qt.vector2d(
            Math.max(1.0, width * root.dpr),
            Math.max(1.0, height * root.dpr)
        )
        readonly property color uColorBg: root.colorBg
        readonly property color uColorPrimary: root.colorPrimary
        readonly property color uColorSecondary: root.colorSecondary
        readonly property color uColorAccent: root.colorAccent
        readonly property vector2d uOffset: Qt.vector2d(root.offsetX, root.offsetY)

        fragmentShader: root.shaderUrls[root.activeBaseIndex]

        onStatusChanged: {
            if (status === ShaderEffect.Error) {
                console.warn("CosmicShaderView base shader error:", log);
            }
        }
    }

    ShaderEffect {
        id: nextShader
        anchors.fill: parent
        supportsAtlasTextures: false
        visible: root.activeBlend > 0.0005
        opacity: root.activeBlend

        readonly property real uTime: root.elapsedTime
        readonly property real uBrightness: root.brightness
        readonly property real uStarDensity: root.starDensity
        readonly property real uColorBalance: root.colorBalance
        readonly property vector2d uResolution: Qt.vector2d(
            Math.max(1.0, width * root.dpr),
            Math.max(1.0, height * root.dpr)
        )
        readonly property color uColorBg: root.colorBg
        readonly property color uColorPrimary: root.colorPrimary
        readonly property color uColorSecondary: root.colorSecondary
        readonly property color uColorAccent: root.colorAccent
        readonly property vector2d uOffset: Qt.vector2d(root.offsetX, root.offsetY)

        fragmentShader: root.shaderUrls[root.activeNextIndex]

        onStatusChanged: {
            if (status === ShaderEffect.Error) {
                console.warn("CosmicShaderView next shader error:", log);
            }
        }
    }

    FrameAnimation {
        running: root.needsHighFps && root.fpsLimit <= 0
        onTriggered: {
            root.advanceTime(Math.min(Math.max(frameTime, 0.0), 0.1));
        }
    }

    Timer {
        id: fpsTimer
        property double lastTickMs: 0

        interval: Math.max(8, Math.round(1000 / Math.max(1, root.fpsLimit)))
        repeat: true
        running: root.needsHighFps && root.fpsLimit > 0

        onRunningChanged: {
            if (running) {
                lastTickMs = Date.now();
            }
        }

        onTriggered: {
            const now = Date.now();
            const dt = Math.min(Math.max((now - lastTickMs) / 1000.0, 0.0), 0.1);
            lastTickMs = now;
            root.advanceTime(dt);
        }
    }

    Timer {
        id: cycleTickTimer
        property double lastTickMs: 0

        interval: 250
        repeat: true
        running: root.needsLowFpsCycleTick

        onRunningChanged: {
            if (running) {
                lastTickMs = Date.now();
            }
        }

        onTriggered: {
            const now = Date.now();
            const dt = Math.min(Math.max((now - lastTickMs) / 1000.0, 0.0), 1.0);
            lastTickMs = now;
            root.cycleClock += dt;
        }
    }
}
