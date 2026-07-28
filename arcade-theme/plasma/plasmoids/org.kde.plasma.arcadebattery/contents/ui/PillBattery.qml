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
    implicitWidth: isCharging ? 48 : 40

    Item {
        id: batteryContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - 4

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

            Shape {
                width: batteryBody.height * 0.375
                height: batteryBody.height * 0.5625
                visible: rootItem.isCharging
                anchors.verticalCenter: parent.verticalCenter
                scale: batteryBody.height / 16.0
                transformOrigin: Item.Center

                ShapePath {
                    fillColor: "#ffffff"
                    strokeWidth: 0
                    startX: 3; startY: 0
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

        // Fill: clip a full-width capsule so the left edge always stays round
        Item {
            id: fillClip
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * (rootItem.batteryPercent / 100.0)
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: batteryContainer.width
                radius: batteryContainer.height / 2
                color: {
                    if (rootItem.isCharging) return "#34c759";
                    if (rootItem.batteryPercent <= 20) return "#ff3b30";
                    if (rootItem.batteryPercent <= 50) return "#ffcc00";
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
                    color: "#000000"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Shape {
                    width: batteryBody.height * 0.375
                    height: batteryBody.height * 0.5625
                    visible: rootItem.isCharging
                    anchors.verticalCenter: parent.verticalCenter
                    scale: batteryBody.height / 16.0
                    transformOrigin: Item.Center

                    ShapePath {
                        fillColor: "#000000"
                        strokeWidth: 0
                        startX: 3; startY: 0
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
    }

    // Battery terminal nub
    Rectangle {
        anchors.left: batteryContainer.right
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height * 0.4
        radius: 1
        color: Qt.rgba(1, 1, 1, 0.5)
    }
}
