/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property var configDialog
    property var wallpaperConfiguration
    property alias formLayout: root

    property int cfg_Preset: -1
    property int cfg_PresetDefault: -1
    property int cfg_CycleHoldSeconds: 360
    property int cfg_CycleHoldSecondsDefault: 360
    property int cfg_CycleBlendSeconds: 3
    property int cfg_CycleBlendSecondsDefault: 3
    property int cfg_SpeedPercent: 75
    property int cfg_SpeedPercentDefault: 75
    property int cfg_StarDensityPercent: 100
    property int cfg_StarDensityPercentDefault: 100
    property int cfg_BrightnessPercent: 100
    property int cfg_BrightnessPercentDefault: 100
    property int cfg_ColorBalance: 0
    property int cfg_ColorBalanceDefault: 0
    property int cfg_OffsetXPercent: 0
    property int cfg_OffsetXPercentDefault: 0
    property int cfg_OffsetYPercent: 0
    property int cfg_OffsetYPercentDefault: 0
    property color cfg_ColorBackground: "#06091c"
    property color cfg_ColorBackgroundDefault: "#06091c"
    property color cfg_ColorPrimary: "#1038b8"
    property color cfg_ColorPrimaryDefault: "#1038b8"
    property color cfg_ColorSecondary: "#8c24e0"
    property color cfg_ColorSecondaryDefault: "#8c24e0"
    property color cfg_ColorAccent: "#0ee8ff"
    property color cfg_ColorAccentDefault: "#0ee8ff"
    property bool cfg_RotateColors: false
    property bool cfg_RotateColorsDefault: false
    property int cfg_FpsLimit: 60
    property int cfg_FpsLimitDefault: 60
    property bool cfg_PauseWhenMaximized: true
    property bool cfg_PauseWhenMaximizedDefault: true

    readonly property var presetModel: [
        { label: qsTr("Auto-Cycle (All Scenes)"), value: -1 },
        { label: qsTr("Cosmic Plasma Nebula"), value: 0 },
        { label: qsTr("Event Horizon Vortex"), value: 1 },
        { label: qsTr("Deep-Space Plasma Aurora"), value: 2 }
    ]

    readonly property var paletteModel: [
        {
            label: qsTr("Cosmic Deep Blue (Default)"),
            bg: "#06091c",
            primary: "#1038b8",
            secondary: "#8c24e0",
            accent: "#0ee8ff",
            custom: false
        },
        {
            label: qsTr("Ultraviolet Nebula"),
            bg: "#120729",
            primary: "#3b1d8a",
            secondary: "#b829e6",
            accent: "#40d9ff",
            custom: false
        },
        {
            label: qsTr("Emerald Abyss"),
            bg: "#061c17",
            primary: "#0b7268",
            secondary: "#1e4fa3",
            accent: "#3effc8",
            custom: false
        },
        {
            label: qsTr("Crimson Event"),
            bg: "#1c0713",
            primary: "#96184a",
            secondary: "#5b1a99",
            accent: "#ff9e2c",
            custom: false
        },
        {
            label: qsTr("Arctic Aurora"),
            bg: "#06162b",
            primary: "#0f5298",
            secondary: "#248ea6",
            accent: "#6ef7ff",
            custom: false
        },
        {
            label: qsTr("Custom"),
            bg: "",
            primary: "",
            secondary: "",
            accent: "",
            custom: true
        }
    ]

    readonly property var fpsModel: [
        { label: qsTr("30 FPS (Low GPU)"), value: 30 },
        { label: qsTr("60 FPS (Smooth)"), value: 60 },
        { label: qsTr("VSync (Display Refresh)"), value: 0 }
    ]

    function syncPresetCombo() {
        for (let i = 0; i < presetModel.length; ++i) {
            if (presetModel[i].value === cfg_Preset) {
                presetCombo.currentIndex = i;
                return;
            }
        }
        presetCombo.currentIndex = 0;
    }

    function syncColorPaletteCombo() {
        for (let i = 0; i < paletteModel.length; ++i) {
            const p = paletteModel[i];
            if (p.custom) {
                continue;
            }
            if (Qt.colorEqual(cfg_ColorBackground, p.bg)
                    && Qt.colorEqual(cfg_ColorPrimary, p.primary)
                    && Qt.colorEqual(cfg_ColorSecondary, p.secondary)
                    && Qt.colorEqual(cfg_ColorAccent, p.accent)) {
                paletteCombo.currentIndex = i;
                return;
            }
        }
        paletteCombo.currentIndex = paletteModel.length - 1;
    }

    function syncColorButtons() {
        if (!Qt.colorEqual(bgColorBtn.color, cfg_ColorBackground)) {
            bgColorBtn.color = cfg_ColorBackground;
        }
        if (!Qt.colorEqual(primaryColorBtn.color, cfg_ColorPrimary)) {
            primaryColorBtn.color = cfg_ColorPrimary;
        }
        if (!Qt.colorEqual(secondaryColorBtn.color, cfg_ColorSecondary)) {
            secondaryColorBtn.color = cfg_ColorSecondary;
        }
        if (!Qt.colorEqual(accentColorBtn.color, cfg_ColorAccent)) {
            accentColorBtn.color = cfg_ColorAccent;
        }
    }

    function syncFpsCombo() {
        for (let i = 0; i < fpsModel.length; ++i) {
            if (fpsModel[i].value === cfg_FpsLimit) {
                fpsCombo.currentIndex = i;
                return;
            }
        }
        fpsCombo.currentIndex = 1;
    }

    function formatColorBalance(val) {
        if (val <= -20) {
            return qsTr("Primary / Highlight (%1)").arg(val);
        }
        if (val >= 20) {
            return qsTr("Secondary (+%1)").arg(val);
        }
        return val === 0 ? qsTr("Balanced (0)") : qsTr("Balanced (%1%2)").arg(val > 0 ? "+" : "").arg(val);
    }

    function formatDuration(seconds) {
        const s = Math.max(0, Math.round(seconds));
        if (s >= 60) {
            const mins = Math.floor(s / 60);
            const rem = s % 60;
            return rem === 0 ? qsTr("%1m").arg(mins) : qsTr("%1m %2s").arg(mins).arg(rem);
        }
        return qsTr("%1 s").arg(s);
    }

    function desktopMajorColorStepSeconds() {
        const slot = Math.max(1, root.cfg_CycleHoldSeconds) + Math.max(0, root.cfg_CycleBlendSeconds);
        return slot * previewShaderView.sceneCount * previewShaderView.colorDesyncFactor;
    }

    function clampOffsetPercent(val) {
        return Math.max(-150, Math.min(150, Math.round(val)));
    }

    function formatOffsetPercent(val) {
        return val === 0 ? qsTr("0%") : qsTr("%1%2%").arg(val > 0 ? "+" : "").arg(val);
    }

    Component.onCompleted: {
        syncColorButtons();
        syncColorPaletteCombo();
    }

    onCfg_PresetChanged: syncPresetCombo()
    onCfg_FpsLimitChanged: syncFpsCombo()
    onCfg_ColorBackgroundChanged: {
        syncColorButtons();
        syncColorPaletteCombo();
    }
    onCfg_ColorPrimaryChanged: {
        syncColorButtons();
        syncColorPaletteCombo();
    }
    onCfg_ColorSecondaryChanged: {
        syncColorButtons();
        syncColorPaletteCombo();
    }
    onCfg_ColorAccentChanged: {
        syncColorButtons();
        syncColorPaletteCombo();
    }

    ColumnLayout {
        Kirigami.FormData.label: qsTr("Preview:")
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        spacing: Kirigami.Units.smallSpacing / 2

        Item {
            id: previewBox
            Layout.fillWidth: true
            implicitWidth: Kirigami.Units.gridUnit * 20
            implicitHeight: Math.round((width > 0 ? width : implicitWidth) * 9 / 16)
            clip: true

            CosmicShaderView {
                id: previewShaderView
                anchors.fill: parent
                anchors.margins: 1
                preset: root.cfg_Preset
                speed: root.cfg_SpeedPercent / 100.0
                starDensity: root.cfg_StarDensityPercent / 100.0
                brightness: root.cfg_BrightnessPercent / 100.0
                colorBalance: root.cfg_ColorBalance / 100.0
                offsetX: root.cfg_OffsetXPercent / 100.0
                offsetY: root.cfg_OffsetYPercent / 100.0
                colorBg: root.cfg_ColorBackground
                colorPrimary: root.cfg_ColorPrimary
                colorSecondary: root.cfg_ColorSecondary
                colorAccent: root.cfg_ColorAccent
                rotateColors: root.cfg_RotateColors
                colorCyclePeriodSeconds: root.cfg_RotateColors ? 36.0 : 0.0
                cycleHoldSeconds: root.cfg_Preset < 0 ? Math.min(root.cfg_CycleHoldSeconds, 5) : root.cfg_CycleHoldSeconds
                cycleBlendSeconds: root.cfg_CycleBlendSeconds
                fpsLimit: 30
                initialTime: 12.0
                paused: !visible
            }

            Item {
                id: reticleContainer
                readonly property real reticleX: previewBox.width * (0.5 + 0.5 * (root.cfg_OffsetXPercent / 100.0))
                readonly property real reticleY: previewBox.height * (0.5 - 0.5 * (root.cfg_OffsetYPercent / 100.0))

                x: reticleX - width / 2
                y: reticleY - height / 2
                width: 24
                height: 24
                opacity: previewDragArea.pressed
                         ? 0.95
                         : (previewDragArea.containsMouse
                            ? 0.78
                            : ((root.cfg_OffsetXPercent !== 0 || root.cfg_OffsetYPercent !== 0) ? 0.45 : 0.0))

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: "transparent"
                    border.width: 1.5
                    border.color: Qt.rgba(0.95, 0.98, 1.0, 0.92)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 1
                    color: Qt.rgba(0.55, 0.88, 1.0, 0.9)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 22
                    color: Qt.rgba(0.55, 0.88, 1.0, 0.9)
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 6
                radius: 4
                color: Qt.rgba(0.03, 0.05, 0.12, 0.78)
                border.width: 1
                border.color: Qt.rgba(0.35, 0.72, 1.0, 0.4)
                implicitWidth: coordBadgeLabel.implicitWidth + 10
                implicitHeight: coordBadgeLabel.implicitHeight + 6
                visible: previewDragArea.containsMouse || previewDragArea.pressed

                QQC2.Label {
                    id: coordBadgeLabel
                    anchors.centerIn: parent
                    font: Kirigami.Theme.smallFont
                    color: "#eef6ff"
                    text: qsTr("X: %1  Y: %2")
                          .arg(root.formatOffsetPercent(root.cfg_OffsetXPercent))
                          .arg(root.formatOffsetPercent(root.cfg_OffsetYPercent))
                }
            }

            MouseArea {
                id: previewDragArea
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                function updateOffsetFromPoint(px, py) {
                    if (previewBox.width <= 0 || previewBox.height <= 0) {
                        return;
                    }
                    const nx = ((px / previewBox.width) - 0.5) * 200.0;
                    const ny = (0.5 - (py / previewBox.height)) * 200.0;
                    root.cfg_OffsetXPercent = root.clampOffsetPercent(nx);
                    root.cfg_OffsetYPercent = root.clampOffsetPercent(ny);
                }

                onPressed: (mouse) => {
                    previewDragArea.updateOffsetFromPoint(mouse.x, mouse.y);
                }

                onPositionChanged: (mouse) => {
                    if (previewDragArea.pressed) {
                        previewDragArea.updateOffsetFromPoint(mouse.x, mouse.y);
                    }
                }

                onDoubleClicked: {
                    root.cfg_OffsetXPercent = 0;
                    root.cfg_OffsetYPercent = 0;
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0.35, 0.72, 1.0, 0.35)
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.72
            text: qsTr("Click or drag preview to shift center (double-click to recenter).")
        }

        QQC2.Label {
            visible: root.cfg_Preset < 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.72
            text: qsTr("Live preview holds 5 s so you can preview transitions (desktop uses %1).")
                  .arg(root.formatDuration(root.cfg_CycleHoldSeconds))
        }

        QQC2.Label {
            visible: root.cfg_RotateColors
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.72
            text: qsTr("Live preview rotates colors quickly (desktop shifts smoothly by ~1 major color every %1, desynced from scene cycling).")
                  .arg(root.formatDuration(root.desktopMajorColorStepSeconds()))
        }
    }

    QQC2.ComboBox {
        id: presetCombo
        Kirigami.FormData.label: qsTr("Preset:")
        Layout.fillWidth: true
        model: root.presetModel
        textRole: "label"
        Component.onCompleted: root.syncPresetCombo()
        onActivated: (index) => {
            root.cfg_Preset = root.presetModel[index].value;
        }
    }

    RowLayout {
        Kirigami.FormData.label: qsTr("Hold Duration:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        enabled: root.cfg_Preset < 0

        QQC2.SpinBox {
            id: holdSpinBox
            from: 5
            to: 3600
            stepSize: 15
            editable: true
            value: root.cfg_CycleHoldSeconds
            onValueModified: {
                root.cfg_CycleHoldSeconds = value;
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            opacity: 0.78
            text: qsTr("sec (%1 per scene)").arg(root.formatDuration(root.cfg_CycleHoldSeconds))
        }
    }

    RowLayout {
        Kirigami.FormData.label: qsTr("Transition Blend:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.SpinBox {
            id: blendSpinBox
            from: 0
            to: 30
            stepSize: 1
            editable: true
            value: root.cfg_CycleBlendSeconds
            onValueModified: {
                root.cfg_CycleBlendSeconds = value;
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            opacity: 0.78
            text: qsTr("sec crossfade")
        }
    }

    QQC2.ComboBox {
        id: paletteCombo
        Kirigami.FormData.label: qsTr("Color Palette:")
        Layout.fillWidth: true
        model: root.paletteModel
        textRole: "label"
        Component.onCompleted: root.syncColorPaletteCombo()
        onActivated: (index) => {
            const p = root.paletteModel[index];
            if (!p.custom) {
                root.cfg_ColorBackground = p.bg;
                root.cfg_ColorPrimary = p.primary;
                root.cfg_ColorSecondary = p.secondary;
                root.cfg_ColorAccent = p.accent;
            }
        }
    }

    GridLayout {
        Kirigami.FormData.label: qsTr("Base Colors:")
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            KQuickControls.ColorButton {
                id: bgColorBtn
                showAlphaChannel: false
                dialogTitle: qsTr("Select Space Void Color")
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: root.cfg_ColorBackground.toString()
                onAccepted: (acceptedColor) => {
                    root.cfg_ColorBackground = acceptedColor;
                }
            }

            QQC2.Label {
                text: qsTr("Space Void (%1)").arg(root.cfg_ColorBackground.toString())
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            KQuickControls.ColorButton {
                id: primaryColorBtn
                showAlphaChannel: false
                dialogTitle: qsTr("Select Primary Glow Color")
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: root.cfg_ColorPrimary.toString()
                onAccepted: (acceptedColor) => {
                    root.cfg_ColorPrimary = acceptedColor;
                }
            }

            QQC2.Label {
                text: qsTr("Primary Glow (%1)").arg(root.cfg_ColorPrimary.toString())
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            KQuickControls.ColorButton {
                id: secondaryColorBtn
                showAlphaChannel: false
                dialogTitle: qsTr("Select Secondary Glow Color")
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: root.cfg_ColorSecondary.toString()
                onAccepted: (acceptedColor) => {
                    root.cfg_ColorSecondary = acceptedColor;
                }
            }

            QQC2.Label {
                text: qsTr("Secondary Glow (%1)").arg(root.cfg_ColorSecondary.toString())
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            KQuickControls.ColorButton {
                id: accentColorBtn
                showAlphaChannel: false
                dialogTitle: qsTr("Select Plasma Highlight Color")
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: root.cfg_ColorAccent.toString()
                onAccepted: (acceptedColor) => {
                    root.cfg_ColorAccent = acceptedColor;
                }
            }

            QQC2.Label {
                text: qsTr("Plasma Highlight (%1)").arg(root.cfg_ColorAccent.toString())
                Layout.fillWidth: true
            }
        }
    }

    QQC2.CheckBox {
        id: rotateColorsCheck
        Kirigami.FormData.label: qsTr("Color Rotation:")
        text: qsTr("Rotate colors slowly over time")
        checked: root.cfg_RotateColors
        onToggled: {
            root.cfg_RotateColors = checked;
        }
    }

    RowLayout {
        Kirigami.FormData.label: qsTr("Animation Speed:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Slider {
            id: speedSlider
            Layout.fillWidth: true
            from: 0
            to: 200
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
            value: root.cfg_SpeedPercent
            onMoved: {
                root.cfg_SpeedPercent = Math.round(value);
            }
        }

        QQC2.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
            horizontalAlignment: Text.AlignRight
            text: qsTr("%1%").arg(root.cfg_SpeedPercent)
        }
    }

    RowLayout {
        Kirigami.FormData.label: qsTr("Star Density:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Slider {
            id: starSlider
            Layout.fillWidth: true
            from: 20
            to: 200
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
            value: root.cfg_StarDensityPercent
            onMoved: {
                root.cfg_StarDensityPercent = Math.round(value);
            }
        }

        QQC2.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
            horizontalAlignment: Text.AlignRight
            text: qsTr("%1%").arg(root.cfg_StarDensityPercent)
        }
    }

    RowLayout {
        Kirigami.FormData.label: qsTr("Brightness:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Slider {
            id: brightnessSlider
            Layout.fillWidth: true
            from: 50
            to: 150
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
            value: root.cfg_BrightnessPercent
            onMoved: {
                root.cfg_BrightnessPercent = Math.round(value);
            }
        }

        QQC2.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
            horizontalAlignment: Text.AlignRight
            text: qsTr("%1%").arg(root.cfg_BrightnessPercent)
        }
    }

    ColumnLayout {
        Kirigami.FormData.label: qsTr("Palette Balance:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: balanceSlider
                Layout.fillWidth: true
                from: -100
                to: 100
                stepSize: 5
                snapMode: QQC2.Slider.SnapAlways
                value: root.cfg_ColorBalance
                onMoved: {
                    root.cfg_ColorBalance = Math.round(value);
                }
            }

            QQC2.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 9
                horizontalAlignment: Text.AlignRight
                text: root.formatColorBalance(root.cfg_ColorBalance)
            }
        }

        RowLayout {
            Layout.fillWidth: true

            QQC2.Label {
                text: qsTr("Primary / Highlight")
                font: Kirigami.Theme.smallFont
                opacity: 0.72
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Secondary")
                font: Kirigami.Theme.smallFont
                opacity: 0.72
            }
        }
    }

    ColumnLayout {
        Kirigami.FormData.label: qsTr("Center Offset:")
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: qsTr("X")
                Layout.minimumWidth: Kirigami.Units.gridUnit
                opacity: 0.85
            }

            QQC2.Slider {
                id: offsetXSlider
                Layout.fillWidth: true
                from: -150
                to: 150
                stepSize: 1
                snapMode: QQC2.Slider.SnapAlways
                value: root.cfg_OffsetXPercent
                onMoved: {
                    root.cfg_OffsetXPercent = Math.round(value);
                }
            }

            QQC2.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: root.formatOffsetPercent(root.cfg_OffsetXPercent)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: qsTr("Y")
                Layout.minimumWidth: Kirigami.Units.gridUnit
                opacity: 0.85
            }

            QQC2.Slider {
                id: offsetYSlider
                Layout.fillWidth: true
                from: -150
                to: 150
                stepSize: 1
                snapMode: QQC2.Slider.SnapAlways
                value: root.cfg_OffsetYPercent
                onMoved: {
                    root.cfg_OffsetYPercent = Math.round(value);
                }
            }

            QQC2.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: root.formatOffsetPercent(root.cfg_OffsetYPercent)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: qsTr("0% center · ±100% edges")
                font: Kirigami.Theme.smallFont
                opacity: 0.72
            }

            QQC2.Button {
                text: qsTr("Center")
                icon.name: "edit-undo"
                enabled: root.cfg_OffsetXPercent !== 0 || root.cfg_OffsetYPercent !== 0
                onClicked: {
                    root.cfg_OffsetXPercent = 0;
                    root.cfg_OffsetYPercent = 0;
                }
            }
        }
    }

    QQC2.ComboBox {
        id: fpsCombo
        Kirigami.FormData.label: qsTr("Frame Rate:")
        Layout.fillWidth: true
        model: root.fpsModel
        textRole: "label"
        Component.onCompleted: root.syncFpsCombo()
        onActivated: (index) => {
            root.cfg_FpsLimit = root.fpsModel[index].value;
        }
    }

    QQC2.CheckBox {
        id: pauseMaxCheck
        Kirigami.FormData.label: qsTr("Power Saving:")
        text: qsTr("Pause animation when a window is maximized or fullscreen")
        checked: root.cfg_PauseWhenMaximized
        onToggled: {
            root.cfg_PauseWhenMaximized = checked;
        }
    }

    QQC2.Button {
        Kirigami.FormData.label: qsTr("Defaults:")
        text: qsTr("Reset to Defaults")
        icon.name: "edit-reset"
        onClicked: {
            root.cfg_Preset = root.cfg_PresetDefault;
            root.cfg_CycleHoldSeconds = root.cfg_CycleHoldSecondsDefault;
            root.cfg_CycleBlendSeconds = root.cfg_CycleBlendSecondsDefault;
            root.cfg_SpeedPercent = root.cfg_SpeedPercentDefault;
            root.cfg_StarDensityPercent = root.cfg_StarDensityPercentDefault;
            root.cfg_BrightnessPercent = root.cfg_BrightnessPercentDefault;
            root.cfg_ColorBalance = root.cfg_ColorBalanceDefault;
            root.cfg_OffsetXPercent = root.cfg_OffsetXPercentDefault;
            root.cfg_OffsetYPercent = root.cfg_OffsetYPercentDefault;
            root.cfg_ColorBackground = root.cfg_ColorBackgroundDefault;
            root.cfg_ColorPrimary = root.cfg_ColorPrimaryDefault;
            root.cfg_ColorSecondary = root.cfg_ColorSecondaryDefault;
            root.cfg_ColorAccent = root.cfg_ColorAccentDefault;
            root.cfg_RotateColors = root.cfg_RotateColorsDefault;
            root.cfg_FpsLimit = root.cfg_FpsLimitDefault;
            root.cfg_PauseWhenMaximized = root.cfg_PauseWhenMaximizedDefault;
        }
    }
}
