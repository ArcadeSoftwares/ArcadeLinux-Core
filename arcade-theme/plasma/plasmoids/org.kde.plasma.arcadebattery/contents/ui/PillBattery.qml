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
    implicitWidth: 40

    property real animatedPercent: batteryPercent

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
        } else {
            chargeFillAnimation.stop()
            animatedPercent = batteryPercent
        }
    }

    NumberAnimation {
        id: chargeFillAnimation
        target: rootItem
        property: "animatedPercent"
        duration: 800
        easing.type: Easing.OutCubic
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
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
        }

        // Unfilled (background) text & icon
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 2

            Text {
                visible: Plasmoid.configuration.showPercentage !== false
                text: rootItem.hasBattery ? rootItem.batteryPercent : "?"
                font.pixelSize: Math.max(9, Math.round(rootItem.height * 0.65))
                font.bold: true
                font.family: "SF Pro Text"
                color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
            }

            Image {
                source: "bolt.svg"
                width: batteryBody.height * 0.4
                height: batteryBody.height * 0.6
                visible: rootItem.isCharging
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                antialiasing: true
                smooth: true
            }
        }

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
                    if (pct <= 50) return "#ffcc00";
                    return "#34c759";
                }
            }

            // Filled (foreground) text & icon inside the clip
            Row {
                x: (batteryContainer.width - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    visible: Plasmoid.configuration.showPercentage !== false
                    text: rootItem.hasBattery ? rootItem.batteryPercent : "?"
                    font.pixelSize: Math.max(9, Math.round(rootItem.height * 0.65))
                    font.bold: true
                    font.family: "SF Pro Text"
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Image {
                    source: "bolt.svg"
                    width: batteryBody.height * 0.4
                    height: batteryBody.height * 0.6
                    visible: rootItem.isCharging
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    smooth: true
                }
            }
        }
    }

}
