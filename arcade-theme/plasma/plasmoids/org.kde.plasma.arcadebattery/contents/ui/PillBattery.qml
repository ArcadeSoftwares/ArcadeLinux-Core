import QtQuick
import QtQuick.Shapes
import org.kde.plasma.plasmoid

Item {
    id: rootItem
    
    property int batteryPercent: 100
    property bool isCharging: false
    property color batteryColor: "#ffffff"
    property bool hasBattery: true
    
    implicitHeight: 20
    implicitWidth: 44

    property real animatedPercent: batteryPercent
    property real boltOffset: 0

    onBatteryPercentChanged: {
        if (chargeFillAnimation.running) {
            chargeFillAnimation.to = batteryPercent
        } else {
            animatedPercent = batteryPercent
        }
    }

    onIsChargingChanged: {
        if (isCharging) {
            animatedPercent = 0
            chargeFillAnimation.to = batteryPercent
            chargeFillAnimation.restart()
            boltDropAnimation.restart()
        } else {
            chargeFillAnimation.stop()
            animatedPercent = batteryPercent
            boltDropAnimation.stop()
            boltOffset = 0
        }
    }

    NumberAnimation {
        id: chargeFillAnimation
        target: rootItem
        property: "animatedPercent"
        duration: 800
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: boltDropAnimation
        target: rootItem
        property: "boltOffset"
        from: -15
        to: 0
        duration: 500
        easing.type: Easing.OutBounce
    }

    Item {
        id: batteryContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width

        // Capsule background track
        Rectangle {
            id: batteryBody
            anchors.fill: parent
            radius: height / 2
            color: "#999999"
            border.color: "#777777"
            border.width: 1
        }

        // Content removed, will be drawn after fillClip

        // Fill: clip a full-width capsule so the left edge always stays round
        Item {
            id: fillClip
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * (rootItem.animatedPercent / 100.0)
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: batteryContainer.width
                radius: batteryContainer.height / 2
                color: {
                    var pct = rootItem.isCharging ? rootItem.animatedPercent : rootItem.batteryPercent;
                    if (pct <= 15) return "#ff3b30";
                    if (pct <= 30) return "#ffcc00";
                    return rootItem.isCharging ? "#34c759" : "#ffffff";
                }
            }

        }
        
        // Foreground contents (Text and Bolt side-by-side)
        Row {
            anchors.centerIn: parent
            spacing: 2
            z: 10

            Text {
                visible: Plasmoid.configuration.showPercentage !== false
                text: rootItem.hasBattery ? (rootItem.batteryPercent + (rootItem.isCharging ? "" : "%")) : "?"
                font.pixelSize: Math.max(9, Math.round(rootItem.height * 0.65))
                font.bold: true
                font.family: "SF Pro Text"
                color: "#000000"
                anchors.verticalCenter: parent.verticalCenter
            }

            Image {
                source: "bolt-black.svg"
                height: batteryContainer.height * 1.5
                width: height * 0.625
                visible: rootItem.isCharging
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: rootItem.boltOffset
                fillMode: Image.PreserveAspectFit
                antialiasing: true
                smooth: true
            }
        }
    }

}
