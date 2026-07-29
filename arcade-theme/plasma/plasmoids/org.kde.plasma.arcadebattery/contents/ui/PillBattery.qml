import QtQuick
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

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

    function triggerAnimation() {
        animatedPercent = 0
        if (isCharging) {
            boltOffset = -50
        }
        chargeFillAnimation.to = batteryPercent
        chargeFillAnimation.restart()
        boltDropAnimation.restart()
    }

    onIsChargingChanged: {
        if (isCharging) {
            triggerAnimation()
        } else {
            chargeFillAnimation.stop()
            animatedPercent = batteryPercent
            boltDropAnimation.stop()
            boltOffset = 0
        }
    }

    Connections {
        target: Plasmoid
        function onExpandedChanged() {
            if (Plasmoid.expanded) {
                triggerAnimation()
            }
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
                    if (pct <= 20) return "#ff3b30";
                    if (pct <= 30) return "#ffcc00";
                    return rootItem.isCharging ? "#34c759" : "#ffffff";
                }
            }

        }
        
        // The Number - Centered, slightly shifted left when warning icon is shown to look balanced
        Text {
            id: batteryNumber
            visible: Plasmoid.configuration.showPercentage !== false
            text: rootItem.hasBattery ? rootItem.batteryPercent : "?"
            font.pixelSize: Math.max(9, Math.round(rootItem.height * 0.65))
            font.bold: true
            font.family: "SF Pro Text"
            color: "#000000"
            anchors.fill: parent
            anchors.rightMargin: warningIcon.visible ? 14 : 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            z: 10
        }

        // The Percentage Sign removed per user request

        // The Bolt - Anchored to the right edge of the pill so it doesn't spill out horizontally
        Image {
            id: chargingBolt
            source: "bolt-black.svg"
            height: batteryContainer.height * 1.5
            width: height * 0.625
            visible: rootItem.isCharging
            anchors.right: parent.right
            anchors.rightMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: rootItem.boltOffset
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            smooth: true
            z: 10
        }

        // Warning / Critical Icon - Vertically centered on the right side of the pill next to the percentage
        Image {
            id: warningIcon
            source: rootItem.batteryPercent <= 20 ? "critical.svg" : "warning.svg"
            height: batteryContainer.height * 0.65
            width: height
            visible: !rootItem.isCharging && rootItem.batteryPercent <= 30
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            smooth: true
            z: 10
        }
    }

}
