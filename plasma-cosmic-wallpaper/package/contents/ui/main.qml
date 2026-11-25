/*
    SPDX-FileCopyrightText: 2026 Reese Jones <reesedrjones@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Window
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

WallpaperItem {
    id: root

    property bool manuallyPaused: false
    readonly property bool hasObscuringWindow: windowMonitorLoader.item ? windowMonitorLoader.item.obscured : false

    readonly property int currentPreset: Number(root.configuration.Preset ?? 0)

    accentColor: {
        switch (currentPreset) {
        case 1:
            return "#38c8ff";
        case 2:
            return "#42a5f5";
        default:
            return "#1fb8e8";
        }
    }

    contextualActions: [
        PlasmaCore.Action {
            text: qsTr("Next Cosmic Preset")
            icon.name: "view-refresh"
            onTriggered: {
                root.configuration.Preset = (root.currentPreset + 1) % 3;
                root.configuration.writeConfig();
            }
        },
        PlasmaCore.Action {
            text: root.manuallyPaused ? qsTr("Resume Cosmic Animation") : qsTr("Pause Cosmic Animation")
            icon.name: root.manuallyPaused ? "media-playback-start" : "media-playback-pause"
            onTriggered: {
                root.manuallyPaused = !root.manuallyPaused;
            }
        }
    ]

    Loader {
        id: windowMonitorLoader
        active: Boolean(root.configuration.PauseWhenMaximized ?? true)

        sourceComponent: Component {
            Item {
                id: monitorItem
                property bool obscured: false

                TaskManager.ActivityInfo {
                    id: activityInfo
                }

                TaskManager.TasksModel {
                    id: tasksModel
                    filterByCurrentVirtualDesktop: true
                    filterByActivity: true
                    filterByScreen: Screen.width > 0 && Screen.height > 0
                    filterHidden: true
                    filterMinimized: true
                    groupMode: TaskManager.TasksModel.GroupDisabled

                    activity: activityInfo.currentActivity
                    screenGeometry: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)

                    function updateObscuringState() {
                        let found = false;
                        const total = rowCount();
                        for (let i = 0; i < total; ++i) {
                            const idx = index(i, 0);
                            const isWindow = Boolean(data(idx, TaskManager.AbstractTasksModel.IsWindow));
                            if (!isWindow) {
                                continue;
                            }
                            const isMax = Boolean(data(idx, TaskManager.AbstractTasksModel.IsMaximized));
                            const isFull = Boolean(data(idx, TaskManager.AbstractTasksModel.IsFullScreen));
                            if (isMax || isFull) {
                                found = true;
                                break;
                            }
                        }
                        monitorItem.obscured = found;
                    }

                    onRowsInserted: updateObscuringState()
                    onRowsRemoved: updateObscuringState()
                    onDataChanged: updateObscuringState()
                    onModelReset: updateObscuringState()
                    onScreenGeometryChanged: updateObscuringState()
                    onActivityChanged: updateObscuringState()
                    Component.onCompleted: updateObscuringState()
                }
            }
        }
    }

    CosmicShaderView {
        id: shaderView
        anchors.fill: parent
        preset: root.currentPreset
        speed: Number(root.configuration.SpeedPercent ?? 75) / 100.0
        starDensity: Number(root.configuration.StarDensityPercent ?? 100) / 100.0
        brightness: Number(root.configuration.BrightnessPercent ?? 100) / 100.0
        colorBalance: Number(root.configuration.ColorBalance ?? 0) / 100.0
        fpsLimit: Number(root.configuration.FpsLimit ?? 60)
        paused: root.manuallyPaused
                || root.hasObscuringWindow
                || (root.Window.window !== null && !root.Window.window.visible)
    }
}
