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
import QtQuick.Shapes
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
        if (isCharging) return "#4ade80"; 
        if (batteryPercent <= 20) return "#ef4444";
        return "#ffffff";
    }

    preferredRepresentation: Plasmoid.compactRepresentation
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

    // --- PANEL CAPSULE ---
    compactRepresentation: MouseArea {
        id: compactRoot
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            root.expanded = !root.expanded;
        }

        Item {
            anchors.centerIn: parent
            width: rowLayout.implicitWidth
            height: 16
            
            RowLayout {
                id: rowLayout
                anchors.centerIn: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: root.isCharging ? 34 : 38
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id: batteryBody
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2
                        height: 16
                        radius: 8 
                        color: Qt.rgba(1, 1, 1, 0.2) 
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.3)
                        
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (root.batteryPercent / 100)
                            radius: 8 
                            color: root.batteryColor
                        }
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 1
                            
                            Text {
                                text: root.hasBattery ? (root.isCharging ? root.batteryPercent : (root.batteryPercent + "%")) : "?"
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "SF Pro Text"
                                color: root.isCharging ? "#ffffff" : PlasmaCore.Theme.backgroundColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Shape {
                                width: 6
                                height: 9
                                visible: root.isCharging
                                anchors.verticalCenter: parent.verticalCenter
                                
                                ShapePath {
                                    fillColor: "#ffffff"
                                    strokeWidth: 0
                                    startX: 3
                                    startY: 0
                                    PathLine { x: 0; y: 5 }
                                    PathLine { x: 3; y: 5 }
                                    PathLine { x: 2; y: 9 }
                                    PathLine { x: 6; y: 4 }
                                    PathLine { x: 3; y: 4 }
                                    PathLine { x: 4; y: 0 }
                                    PathLine { x: 3; y: 0 }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: batteryBody.right
                        anchors.verticalCenter: batteryBody.verticalCenter
                        width: 2
                        height: 6
                        radius: 1
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }
                }
            }
        }
        
        ToolTip {
            visible: parent.containsMouse
            delay: 500
            text: {
                if (!root.hasBattery) return "No battery detected";
                return "Battery: " + root.batteryPercent + "%\nStatus: " + root.batteryState;
            }
        }
    }

    // --- POPUP MENU (macOS style) ---
    fullRepresentation: Item {
        Layout.preferredWidth: 300
        Layout.preferredHeight: 180

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                spacing: 12
                
                PlasmaCore.IconItem {
                    source: root.isCharging ? "battery-charging" : "battery-100"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    colorGroup: PlasmaCore.Theme.NormalColorGroup
                }
                
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Battery: " + root.batteryPercent + "%"
                        font.pixelSize: 16
                        font.bold: true
                        color: PlasmaCore.Theme.textColor
                    }
                    Text {
                        text: "Power Source: " + (root.isCharging ? "Power Adapter" : "Battery")
                        font.pixelSize: 12
                        color: PlasmaCore.Theme.neutralTextColor
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(PlasmaCore.Theme.textColor.r, PlasmaCore.Theme.textColor.g, PlasmaCore.Theme.textColor.b, 0.2)
            }

            Button {
                Layout.fillWidth: true
                text: "Battery Settings..."
                icon.name: "preferences-system-power-management"
                onClicked: {
                    Qt.openUrlExternally("kcm:powerdevilprofilesconfig");
                    root.expanded = false;
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
