/*
 * Arcade Circular Battery - KDE Plasma 6 Plasmoid
 * A sleek circular battery indicator with percentage display
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

    readonly property color batteryColor: {
        if (isCharging) return "#4ade80";          // green when charging
        if (batteryPercent <= 20) return "#ef4444"; // red critical
        if (batteryPercent <= 40) return "#facc15"; // yellow medium-low
        return "#ffffff";                           // white normal
    }

    // White outline for the track
    readonly property color trackColor: Qt.rgba(1.0, 1.0, 1.0, 0.2)

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

        Layout.preferredWidth: topPanel_height
        Layout.preferredHeight: topPanel_height
        Layout.minimumWidth: 22
        Layout.minimumHeight: 22

        readonly property real topPanel_height: parent ? Math.min(parent.height, parent.width || parent.height) : 28
        readonly property real circleSize: Math.min(width, height)
        readonly property real strokeWidth: Math.max(2, circleSize * 0.13)

        Canvas {
            id: batteryCanvas
            anchors.centerIn: parent
            width: batteryItem.circleSize
            height: batteryItem.circleSize
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);

                var cx = width / 2;
                var cy = height / 2;
                var lineW = batteryItem.strokeWidth;
                var radius = (Math.min(width, height) - lineW) / 2 - 1;
                var startAngle = -Math.PI / 2; // 12 o'clock

                // ── Track (background ring) ──
                ctx.beginPath();
                ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                ctx.lineWidth = lineW;
                ctx.strokeStyle = root.trackColor.toString();
                ctx.lineCap = "round";
                ctx.stroke();

                // ── Progress arc ──
                var fraction = root.batteryPercent / 100.0;
                var endAngle = startAngle + (fraction * 2 * Math.PI);

                ctx.beginPath();
                ctx.arc(cx, cy, radius, startAngle, endAngle);
                ctx.lineWidth = lineW;
                ctx.strokeStyle = root.batteryColor.toString();
                ctx.lineCap = "round";
                ctx.stroke();
            }

            // Repaint when values change
            Connections {
                target: root
                function onBatteryPercentChanged() { batteryCanvas.requestPaint(); }
                function onBatteryColorChanged()   { batteryCanvas.requestPaint(); }
                function onTrackColorChanged()     { batteryCanvas.requestPaint(); }
            }
        }

        // ── Percentage text / bolt in center ──
        Text {
            anchors.centerIn: parent
            text: {
                if (!root.hasBattery) return "?";
                if (root.isCharging && root.batteryPercent < 100) {
                    return "⚡\n" + root.batteryPercent + "%";
                }
                return root.batteryPercent + "%";
            }
            font.pixelSize: Math.max(7, batteryItem.circleSize * (root.isCharging ? 0.25 : 0.30))
            font.bold: true
            font.family: "SF Pro Text"
            color: "#ffffff" // White text and electric icon
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
                    if (root.isCharging) s += " (Charging)";
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
