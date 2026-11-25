/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property alias formLayout: root

    property int cfg_Preset: 0
    property int cfg_PresetDefault: 0
    property int cfg_SpeedPercent: 75
    property int cfg_SpeedPercentDefault: 75
    property int cfg_StarDensityPercent: 100
    property int cfg_StarDensityPercentDefault: 100
    property int cfg_BrightnessPercent: 100
    property int cfg_BrightnessPercentDefault: 100
    property int cfg_ColorBalance: 0
    property int cfg_ColorBalanceDefault: 0
    property int cfg_FpsLimit: 60
    property int cfg_FpsLimitDefault: 60
    property bool cfg_PauseWhenMaximized: true
    property bool cfg_PauseWhenMaximizedDefault: true

    readonly property var presetModel: [
        { label: qsTr("Cosmic Plasma Nebula"), value: 0 },
        { label: qsTr("Event Horizon Vortex"), value: 1 },
        { label: qsTr("Deep-Space Plasma Aurora"), value: 2 }
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
            return qsTr("Deep Blue / Cyan (%1)").arg(val);
        }
        if (val >= 20) {
            return qsTr("Purple / Violet (+%1)").arg(val);
        }
        return val === 0 ? qsTr("Balanced (0)") : qsTr("Balanced (%1%2)").arg(val > 0 ? "+" : "").arg(val);
    }

    onCfg_PresetChanged: syncPresetCombo()
    onCfg_FpsLimitChanged: syncFpsCombo()

    Item {
        Kirigami.FormData.label: qsTr("Preview:")
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Math.round((width > 0 ? width : implicitWidth) * 9 / 16)

        CosmicShaderView {
            anchors.fill: parent
            anchors.margins: 1
            preset: root.cfg_Preset
            speed: root.cfg_SpeedPercent / 100.0
            starDensity: root.cfg_StarDensityPercent / 100.0
            brightness: root.cfg_BrightnessPercent / 100.0
            colorBalance: root.cfg_ColorBalance / 100.0
            fpsLimit: 30
            initialTime: 12.0
            paused: !visible
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0.35, 0.72, 1.0, 0.35)
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
                text: qsTr("Deep Blue / Cyan")
                font: Kirigami.Theme.smallFont
                opacity: 0.72
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: qsTr("Purple / Violet")
                font: Kirigami.Theme.smallFont
                opacity: 0.72
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
            root.cfg_SpeedPercent = root.cfg_SpeedPercentDefault;
            root.cfg_StarDensityPercent = root.cfg_StarDensityPercentDefault;
            root.cfg_BrightnessPercent = root.cfg_BrightnessPercentDefault;
            root.cfg_ColorBalance = root.cfg_ColorBalanceDefault;
            root.cfg_FpsLimit = root.cfg_FpsLimitDefault;
            root.cfg_PauseWhenMaximized = root.cfg_PauseWhenMaximizedDefault;
        }
    }
}
