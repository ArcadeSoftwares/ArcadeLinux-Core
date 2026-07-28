/*
 * Arcade Battery - KDE Plasma 6 Plasmoid
 * A sleek modern battery indicator with percentage display
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
        interval: 1000
        
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

    // REUSABLE BATTERY PILL UI
    Component {
        id: pillBattery
        Item {
            implicitWidth: myIsCharging ? 38 : 32
            implicitHeight: 16

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
                    width: parent.width * (myBatteryPercent / 100)
                    radius: 8 
                    color: myBatteryColor
                    clip: true
                    
                    // Square off the right edge so the battery fluid looks flat
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 8
                        color: parent.color
                        // Show flat edge only when it hasn't reached the right curved corner
                        visible: fillRect.width > 8 && fillRect.width < (batteryBody.width - 4)
                    }
                }
                
                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Shape {
                        width: 6
                        height: 9
                        visible: myIsCharging
                        anchors.verticalCenter: parent.verticalCenter
                        
                        ShapePath {
                            fillColor: Plasmoid.configuration.chargingTextColor || "#000000"
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
                    
                    Text {
                        visible: Plasmoid.configuration.showPercentage !== false
                        text: myHasBattery ? (myIsCharging ? myBatteryPercent : (myBatteryPercent + "%")) : "?"
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "SF Pro Text"
                        color: {
                            if (myIsCharging) return Plasmoid.configuration.chargingTextColor || "#000000";
                            return Plasmoid.configuration.textColor || "#000000";
                        }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
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

        Loader {
            anchors.centerIn: parent
            property int myBatteryPercent: root.batteryPercent
            property bool myIsCharging: root.isCharging
            property color myBatteryColor: root.batteryColor
            property bool myHasBattery: root.hasBattery
            sourceComponent: pillBattery
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
            
            // Use custom pill instead of standard global icon
            Item {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                
                Loader {
                    anchors.centerIn: parent
                    property int myBatteryPercent: root.batteryPercent
                    property bool myIsCharging: root.isCharging
                    property color myBatteryColor: root.batteryColor
                    property bool myHasBattery: root.hasBattery
                    sourceComponent: pillBattery
                    // Make it 50% larger for the header
                    transform: Scale { origin.x: width/2; origin.y: height/2; xScale: 1.5; yScale: 1.5 }
                }
            }
            
            ColumnLayout {
                spacing: 0
                Text {
                    text: "Battery: " + root.batteryPercent + "%"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ffffff" // Force white text to contrast dark background
                }
                Text {
                    text: "Power Source: " + (root.isCharging ? "Power Adapter" : "Battery")
                    font.pixelSize: 12
                    color: "#cccccc" // Force light gray for subtitle
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            height: 1
            color: Qt.rgba(1, 1, 1, 0.2) // Force white line
        }
        
        // Connected Devices (Bluetooth, Mouse, etc.)
        Repeater {
            model: pmSource.connectedSources
            delegate: Item {
                id: deviceDelegate
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
                    
                    Loader {
                        property int myBatteryPercent: deviceDelegate.deviceData["Percent"] !== undefined ? deviceDelegate.deviceData["Percent"] : 0
                        property bool myIsCharging: false
                        property color myBatteryColor: myBatteryPercent <= 20 ? "#ef4444" : "#ffffff"
                        property bool myHasBattery: true
                        sourceComponent: pillBattery
                    }
                    
                    Text {
                        text: parent.deviceData["Pretty Name"] || modelData
                        font.pixelSize: 13
                        color: "#ffffff" // Force white text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: (parent.deviceData["Percent"] !== undefined ? parent.deviceData["Percent"] : "?") + "%"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff" // Force white text
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            height: 1
            color: Qt.rgba(1, 1, 1, 0.2) // Force white line
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
