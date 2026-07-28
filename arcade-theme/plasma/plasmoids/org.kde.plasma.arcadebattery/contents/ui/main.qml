/*
 * Arcade iOS Battery - KDE Plasma 6 Plasmoid
 * A sleek iOS-style battery indicator replicating the iOS 16 battery percentage icon
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

    // Battery fill color: green if charging, red if critical, else white
    readonly property color batteryColor: {
        if (isCharging) return "#4ade80"; 
        if (batteryPercent <= 20) return "#ef4444";
        return "#ffffff";
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Plasma5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 1000 // Real-time 1s updates
    }
    
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        
        function notify(title, msg, icon) {
            var cmd = "notify-send '" + title + "' '" + msg + "' -i " + icon;
            connectSource(cmd);
        }
        
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
        }
    }
    
    onIsChargingChanged: {
        if (isCharging) {
            execSource.notify("Battery Status", "Charging Connected", "battery-charging");
        }
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
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter

                // Battery body (translucent background)
                Rectangle {
                    id: batteryBody
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42
                    height: 22
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.2) // dark theme translucent
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    
                    // Battery fill
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (root.batteryPercent / 100)
                        radius: 6
                        color: root.batteryColor
                    }
                    
                    // Text and bolt inside
                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text {
                            text: root.hasBattery ? root.batteryPercent : "?"
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "SF Pro Text"
                            color: PlasmaCore.Theme.backgroundColor // dark cutout text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            visible: root.isCharging
                            text: "⚡"
                            font.pixelSize: 11
                            color: PlasmaCore.Theme.backgroundColor // dark cutout bolt
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Battery terminal (cap)
                Rectangle {
                    anchors.left: batteryBody.right
                    anchors.verticalCenter: batteryBody.verticalCenter
                    width: 3
                    height: 8
                    radius: 1.5
                    color: Qt.rgba(1, 1, 1, 0.4)
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
                // Open KDE Power Management settings
                Qt.openUrlExternally("kcm:powerdevilprofilesconfig");
            }
        }
    }
}
