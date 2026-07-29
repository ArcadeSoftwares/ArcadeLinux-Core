import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // Panel Icon
    compactRepresentation: MouseArea {
        implicitWidth: 32
        implicitHeight: 32
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: "search"
            color: parent.containsMouse ? "#ffffff" : "#cccccc"
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }
    
    // Transparent fullscreen wrapper
    fullRepresentation: Item {
        id: fullRoot
        Layout.minimumWidth: Screen.desktopAvailableWidth || 1920
        Layout.minimumHeight: Screen.desktopAvailableHeight || 1080
        
        Kicker.RunnerModel {
            id: runnerModel
            appletInterface: plasmoid
            query: searchField.text
            mergeResults: true
        }

        // Center entire assembly
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -(parent.height * 0.15) // Slightly above absolute center
            spacing: 24
            width: 800
            
            // 1. The Search Pill
            Rectangle {
                id: searchPill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 650
                height: 72
                radius: height / 2 // Perfect pill shape
                
                // Deep glassmorphism gradient look
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.15, 0.15, 0.15, 0.85) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.08, 0.08, 0.95) }
                }
                
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1
                
                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(0, 0, 0, 0.5)
                    border.width: 2
                    z: -1
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 30
                    anchors.rightMargin: 30
                    spacing: 16
                    
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.pixelSize: 28
                        font.weight: Font.Normal
                        color: "#ffffff"
                        placeholderText: "Search or Ask"
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.6)
                        background: Item {} // Remove default background
                        verticalAlignment: TextInput.AlignVCenter
                        
                        onAccepted: {
                            if (runnerModel.count > 0) {
                                if (resultsList.model && resultsList.model.trigger) {
                                    resultsList.model.trigger(resultsList.currentIndex >= 0 ? resultsList.currentIndex : 0, "", null)
                                }
                                root.expanded = false
                            }
                        }
                        
                        Keys.onDownPressed: {
                            resultsList.forceActiveFocus()
                            if (resultsList.currentIndex < 0) resultsList.currentIndex = 0
                        }
                    }
                    
                    // Microphone Icon
                    Kirigami.Icon {
                        source: "audio-input-microphone"
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        color: Qt.rgba(1, 1, 1, 0.7)
                    }
                }
            }
            
            // 2. The Results Window (only shows when there are results)
            Rectangle {
                id: resultsContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: 800
                height: Math.min(500, resultsList.contentHeight + 40)
                visible: runnerModel.count > 0 && searchField.text !== ""
                
                radius: 24
                color: Qt.rgba(0.1, 0.1, 0.1, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                
                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                    spacing: 4
                    
                    delegate: Item {
                        width: ListView.view.width
                        height: 64
                        
                        Rectangle {
                            anchors.fill: parent
                            color: mouseArea.containsMouse || resultsList.currentIndex === index ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                            radius: 12
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 16
                                
                                Kirigami.Icon {
                                    source: model.decoration || "application-x-executable"
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Text {
                                        text: model.display || ""
                                        color: "#ffffff"
                                        font.pixelSize: 18
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Text {
                                        text: model.description || ""
                                        color: Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (resultsList.model && resultsList.model.trigger) {
                                        resultsList.model.trigger(index, "", null)
                                    }
                                    root.expanded = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
