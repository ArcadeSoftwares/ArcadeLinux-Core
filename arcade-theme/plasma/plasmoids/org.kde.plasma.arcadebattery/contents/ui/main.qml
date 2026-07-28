/*
 * Arcade Battery - KDE Plasma 6 Plasmoid
 * A sleek modern battery indicator with percentage display
 * 
 * Copyright 2024 Arcade Softwares
 * License: GPL-3.0+
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    // --- PANEL CAPSULE ---
    compactRepresentation: MouseArea {
        id: compactRoot
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            root.expanded = !root.expanded;
        }

        PillBattery {
            anchors.centerIn: parent
            batteryPercent: root.batteryPercent
            isCharging: root.isCharging
            batteryColor: root.batteryColor
            hasBattery: root.hasBattery
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
            
            // Standard battery icon for popup header
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
                implicitHeight: isValidDevice ? 28 : 0
                
                property var deviceData: pmSource.data[modelData] || {}
                property bool isLaptopBattery: deviceData["Type"] === "Battery" || modelData.indexOf("Battery") !== -1 || modelData === "BAT0"
                property int devPercent: deviceData["Percent"] !== undefined ? deviceData["Percent"] : (deviceData["Capacity"] !== undefined ? deviceData["Capacity"] : -1)
                property bool isValidDevice: !isLaptopBattery && modelData !== "AC Adapter" && modelData !== "Sleep States" && modelData !== "PowerDevil" && devPercent !== -1
                
                visible: isValidDevice

                RowLayout {
                    anchors.fill: parent
                    visible: deviceDelegate.isValidDevice
                    spacing: 8
                    
                    PillBattery {
                        batteryPercent: deviceDelegate.devPercent !== -1 ? deviceDelegate.devPercent : 0
                        isCharging: false
                        batteryColor: batteryPercent <= 20 ? "#ef4444" : "#ffffff"
                        hasBattery: true
                    }
                    
                    Text {
                        text: deviceDelegate.deviceData["Pretty Name"] || modelData
                        font.pixelSize: 13
                        color: "#ffffff" // Force white text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: (deviceDelegate.devPercent !== -1 ? deviceDelegate.devPercent : "?") + "%"
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
