import QtQuick
import QtQuick.Shapes
import org.kde.plasma.plasmoid

Item {
    id: rootItem
    
    property int batteryPercent: 100
    property bool isCharging: false
    property color batteryColor: "#ffffff"
    property bool hasBattery: true
    
    implicitWidth: isCharging ? 38 : 32
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
            width: parent.width * (rootItem.batteryPercent / 100)
            radius: 8 
            color: rootItem.batteryColor
            clip: true
            
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 8
                color: parent.color
                visible: fillRect.width > 8 && fillRect.width < (batteryBody.width - 4)
            }
        }
        
        Row {
            anchors.centerIn: parent
            spacing: 2
            
            Shape {
                width: 6
                height: 9
                visible: rootItem.isCharging
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
                text: rootItem.hasBattery ? (rootItem.isCharging ? rootItem.batteryPercent : (rootItem.batteryPercent + "%")) : "?"
                font.pixelSize: 10
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
}
