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
    
    ListModel {
        id: btDevices
    }

    Plasma5Support.DataSource {
        id: upowerSource
        engine: "executable"
        interval: 10000 // Poll every 10 seconds
        
        Component.onCompleted: {
            connectSource("upower -d");
        }
        
        onNewData: function(sourceName, data) {
            if (sourceName !== "upower -d") return;
            var out = data["stdout"] || "";
            var blocks = out.split("Device: ");
            btDevices.clear();
            
            for (var i = 1; i < blocks.length; i++) {
                var block = blocks[i];
                var lines = block.split("\n");
                var path = lines[0].trim();
                
                if (path.indexOf("battery_BAT") !== -1 || path.indexOf("DisplayDevice") !== -1 || path.indexOf("line_power") !== -1) {
                    continue;
                }
                
                var devName = "Bluetooth Device";
                var devPct = -1;
                
                for (var j = 1; j < lines.length; j++) {
                    var line = lines[j].trim();
                    if (line.indexOf("model:") === 0) {
                        devName = line.substring(6).trim();
                    } else if (line.indexOf("percentage:") === 0) {
                        var pStr = line.substring(11).trim().replace("%", "");
                        devPct = parseInt(pStr);
                    }
                }
                
                if (devPct !== -1) {
                    btDevices.append({ "prettyName": devName, "percent": devPct });
                }
            }
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
            
            // Use custom pill instead of standard global icon
            Item {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 32
                
                PillBattery {
                    anchors.centerIn: parent
                    batteryPercent: root.batteryPercent
                    isCharging: root.isCharging
                    batteryColor: root.batteryColor
                    hasBattery: root.hasBattery
                    scale: 1.5
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
            visible: btDevices.count > 0
        }
        
        // Connected Devices (Bluetooth, Mouse, etc.)
        Repeater {
            model: btDevices
            delegate: Item {
                id: deviceDelegate
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                implicitHeight: 28

                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    PillBattery {
                        batteryPercent: model.percent
                        isCharging: false
                        batteryColor: model.percent <= 20 ? "#ef4444" : "#ffffff"
                        hasBattery: true
                    }
                    
                    Text {
                        text: model.prettyName
                        font.pixelSize: 13
                        color: "#ffffff" // Force white text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: model.percent + "%"
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
