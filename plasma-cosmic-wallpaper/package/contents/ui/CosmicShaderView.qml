/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick

Item {
    id: root

    property int preset: 0
    property real speed: 0.75
    property real starDensity: 1.0
    property real brightness: 1.0
    property real colorBalance: 0.0
    property int fpsLimit: 60
    property bool paused: false
    property real initialTime: 0.0
    property real elapsedTime: initialTime

    readonly property real dpr: (Screen.devicePixelRatio > 0) ? Screen.devicePixelRatio : 1.0
    readonly property bool animating: visible && !paused && speed > 0.001

    onInitialTimeChanged: {
        elapsedTime = initialTime;
    }

    Rectangle {
        anchors.fill: parent
        color: "#030510"
    }

    ShaderEffect {
        id: shaderEffect
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

        fragmentShader: {
            switch (root.preset) {
            case 1:
                return Qt.resolvedUrl("../shaders/event_horizon.frag.qsb");
            case 2:
                return Qt.resolvedUrl("../shaders/deep_aurora.frag.qsb");
            default:
                return Qt.resolvedUrl("../shaders/cosmic_nebula.frag.qsb");
            }
        }

        onStatusChanged: {
            if (status === ShaderEffect.Error) {
                console.warn("CosmicShaderView shader error:", log);
            }
        }
    }

    FrameAnimation {
        running: root.animating && root.fpsLimit <= 0
        onTriggered: {
            root.elapsedTime += Math.min(Math.max(frameTime, 0.0), 0.1) * root.speed;
        }
    }

    Timer {
        id: fpsTimer
        property double lastTickMs: 0

        interval: Math.max(8, Math.round(1000 / Math.max(1, root.fpsLimit)))
        repeat: true
        running: root.animating && root.fpsLimit > 0

        onRunningChanged: {
            if (running) {
                lastTickMs = Date.now();
            }
        }

        onTriggered: {
            const now = Date.now();
            const dt = Math.min(Math.max((now - lastTickMs) / 1000.0, 0.0), 0.1);
            lastTickMs = now;
            root.elapsedTime += dt * root.speed;
        }
    }
}
