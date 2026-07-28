import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid

Item {
    id: rootItem
    
    property int batteryPercent: 100
    property bool isCharging: false
    property color batteryColor: "#ffffff"
    property bool hasBattery: true
    
    implicitHeight: 16
    implicitWidth: isCharging ? 38 : 32

    // Capsule body (background track)
    Rectangle {
        id: batteryBody
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.25)
    }

    // Fill layer — clipped to the capsule shape via layer + OpacityMask
    Item {
        id: fillContainer
        anchors.fill: parent

        // The actual colored fill pill
        Rectangle {
            id: fillPill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0.01, rootItem.batteryPercent / 100)
            radius: height / 2
            color: rootItem.batteryColor
        }

        // Mask source — same capsule shape as the body
        Rectangle {
            id: maskSource
            anchors.fill: parent
            radius: height / 2
            color: "white"
            visible: false
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: maskSource
        }
    }

    // Text + lightning bolt overlay
    Row {
        anchors.centerIn: parent
        spacing: batteryBody.height * 0.125

        Shape {
            width: batteryBody.height * 0.375
            height: batteryBody.height * 0.5625
            visible: rootItem.isCharging
            anchors.verticalCenter: parent.verticalCenter

            scale: batteryBody.height / 16.0
            transformOrigin: Item.Center

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
            text: rootItem.hasBattery ? (rootItem.isCharging ? rootItem.batteryPercent : (rootItem.batteryPercent + "%")) : "?"
            font.pixelSize: Math.max(8, Math.round(rootItem.height * 0.625))
            font.bold: true
            font.family: "SF Pro Text"
            color: {
                if (rootItem.isCharging) return Plasmoid.configuration.chargingTextColor || "#000000";
                return Plasmoid.configuration.textColor || "#000000";
            }
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
