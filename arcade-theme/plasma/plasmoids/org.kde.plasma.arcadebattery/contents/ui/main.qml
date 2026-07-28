/*
 * Arcade iOS Battery - KDE Plasma 6 Plasmoid
 * A sleek iOS-style battery indicator with percentage display
 * 
 * Copyright 2024 Arcade Softwares
 * License: GPL-2.0+
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    readonly property int batteryPercent: {
        var start = pmSource.data["Battery"] || {};
        var pct = start["Percent"];
        return (pct !== undefined) ? pct : 100;
    }

    readonly property bool isCharging: {
        var acData = pmSource.data["AC Adapter"] || {};
        return acData["Plugged in"] === true;
    }

    readonly property bool hasBattery: {
        var batData = pmSource.data["Battery"] || {};
        return batData["Has Battery"] === true || batData["Percent"] !== undefined;
    }
    
    readonly property string batteryState: {
        var batData = pmSource.data["Battery"] || {};
        var state = batData["State"];
        if (state === "Charging") return "Charging";
        if (state === "Discharging") return "Discharging";
        if (state === "FullyCharged") return "Fully Charged";
        if (isCharging) return "Charging";
        return "Discharging";
    }

    readonly property color batteryColor: {
        if (isCharging) return "#4ade80";          // green when charging
        if (batteryPercent <= 20) return "#ef4444"; // red critical
        if (batteryPercent <= 40) return "#facc15"; // yellow low
        return PlasmaCore.Theme.textColor;          // normal theme color (responsive)
    }

    readonly property color borderColor: Qt.rgba(
        PlasmaCore.Theme.textColor.r,
        PlasmaCore.Theme.textColor.g,
        PlasmaCore.Theme.textColor.b,
        0.8
    )
    
    readonly property color internalTextColor: {
        if (isCharging || batteryPercent <= 40 || batteryPercent > 50) {
            return PlasmaCore.Theme.backgroundColor;
        }
        return PlasmaCore.Theme.textColor;
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Plasma5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 1000 // Update every second to feel instantaneous
    }

    fullRepresentation: Item {
        id: batteryItem

        Layout.preferredWidth: rowLayout.implicitWidth
        Layout.preferredHeight: topPanel_height
        Layout.minimumWidth: rowLayout.implicitWidth
        Layout.minimumHeight: 22

        readonly property real topPanel_height: parent ? Math.min(parent.height, parent.width || parent.height) : 28

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 0

            Item {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter

                // Battery body
                Rectangle {
                    id: batteryBody
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 43
                    height: 20
                    radius: 5
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.borderColor
                    
                    // Battery fill
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        width: Math.max(0, (parent.width - 4) * (root.batteryPercent / 100))
                        radius: 3
                        color: root.batteryColor
                    }
                    
                    // Percentage and bolt text inside battery
                    Text {
                        anchors.centerIn: parent
                        text: root.hasBattery ? ((root.isCharging ? "⚡ " : "") + root.batteryPercent + "%") : ""
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "SF Pro Text"
                        color: root.internalTextColor
                    }
                }

                // Battery terminal (cap)
                Rectangle {
                    anchors.left: batteryBody.right
                    anchors.verticalCenter: batteryBody.verticalCenter
                    anchors.leftMargin: 1
                    width: 2
                    height: 7
                    radius: 1
                    color: root.borderColor
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            ToolTip {
                id: tooltip
                visible: parent.containsMouse
                delay: 500
                text: {
                    if (!root.hasBattery) return "No battery detected";
                    var s = "Battery: " + root.batteryPercent + "%";
                    s += "\nStatus: " + root.batteryState;
                    return s;
                }
            }

            onClicked: {
                Qt.openUrlExternally("kcm:powerdevilprofilesconfig");
            }
        }
    }
}
