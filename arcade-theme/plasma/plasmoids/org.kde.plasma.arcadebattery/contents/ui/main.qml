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
import org.kde.kirigami as Kirigami
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
        interval: 1000 // Real-time 1s updates
        
        Component.onCompleted: {
            connectSource("Battery");
            connectSource("AC Adapter");
        }
        
        onSourcesChanged: {
            for (var i = 0; i < sources.length; ++i) {
                var s = sources[i];
                if (s !== "Sleep States" && s !== "PowerDevil") {
                    connectSource(s);
                }
            }
        }
    }
    
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        
        function notify(title, msg, icon) {
            var cmd = "notify-send '" + title + "' '" + msg + "' -i " + icon;
            connectSource(cmd);
        }
        
        function openSettings() {
            var cmd = "kcmshell6 kcm_powerdevilprofilesconfig";
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
                    Layout.preferredWidth: root.isCharging ? 38 : 32
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id: batteryBody
                        anchors.fill: parent
                        radius: 8 
                        color: Qt.rgba(1, 1, 1, 0.25) 
                        
                        Rectangle {
                            id: fillRect
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (root.batteryPercent / 100)
                            radius: 8 
                            color: root.batteryColor
                            clip: true
                        }
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            // Charging bolt (on the left)
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
                            
                            // Percentage number (% sign ONLY when not charging)
                            Text {
                                text: root.hasBattery ? (root.isCharging ? root.batteryPercent : (root.batteryPercent + "%")) : "?"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "SF Pro Text"
                                color: {
                                    if (root.isCharging) return "#ffffff";
                                    if (root.batteryPercent > 50) return "#000000";
                                    return "#ffffff";
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
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
    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: 300
        spacing: 12

        RowLayout {
            spacing: 12
            Layout.margins: 12
            Layout.bottomMargin: 0
            
            Kirigami.Icon {
                source: root.isCharging ? "battery-charging" : "battery-100"
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
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
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            height: 1
            color: Qt.rgba(PlasmaCore.Theme.textColor.r, PlasmaCore.Theme.textColor.g, PlasmaCore.Theme.textColor.b, 0.2)
        }
        
        // Connected Devices (Bluetooth, Mouse, etc.)
        Repeater {
            model: pmSource.connectedSources
            delegate: Item {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                implicitHeight: visible ? 28 : 0
                
                property var deviceData: pmSource.data[modelData] || {}
                property bool isValidDevice: modelData !== "Battery" && modelData !== "AC Adapter" && deviceData["Percent"] !== undefined
                
                visible: isValidDevice

                RowLayout {
                    anchors.fill: parent
                    visible: parent.isValidDevice
                    spacing: 8
                    
                    Kirigami.Icon {
                        source: {
                            var type = parent.deviceData["Type"] || "";
                            if (type === "Mouse") return "input-mouse";
                            if (type === "Keyboard") return "input-keyboard";
                            if (type === "Bluetooth") return "preferences-system-bluetooth";
                            if (type === "Phone") return "smartphone";
                            return "battery-050";
                        }
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                    }
                    
                    Text {
                        text: parent.deviceData["Pretty Name"] || modelData
                        font.pixelSize: 13
                        color: PlasmaCore.Theme.textColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: (parent.deviceData["Percent"] !== undefined ? parent.deviceData["Percent"] : "?") + "%"
                        font.pixelSize: 13
                        font.bold: true
                        color: PlasmaCore.Theme.textColor
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            height: 1
            color: Qt.rgba(PlasmaCore.Theme.textColor.r, PlasmaCore.Theme.textColor.g, PlasmaCore.Theme.textColor.b, 0.2)
            visible: pmSource.connectedSources.length > 2
        }

        Button {
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            text: "Battery Settings..."
            icon.name: "preferences-system-power-management"
            onClicked: {
                execSource.openSettings();
                root.expanded = false;
            }
        }
    }
}
