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
        Layout.minimumWidth: 600
        Layout.minimumHeight: 400
        
        Kicker.RunnerModel {
            id: runnerModel
            appletInterface: plasmoid
            query: searchField.text
            mergeResults: true
        }

        // Spotlight Container
        Rectangle {
            id: spotlightContainer
            width: 600
            height: Math.min(600, 80 + (resultsList.count * 60))
            anchors.centerIn: parent
            
            color: Qt.rgba(0.1, 0.1, 0.1, 0.85)
            radius: 12
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
            
            // Glassmorphism Blur (requires Plasma 6 effects or just simple rectangle)
            // We use simple translucent background which Plasma composites beautifully
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0
                
                // Search Input Area
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16
                        
                        Kirigami.Icon {
                            source: "search"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: "#ffffff"
                        }
                        
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            font.pixelSize: 28
                            font.weight: Font.Light
                            color: "#ffffff"
                            placeholderText: "Spotlight Search..."
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                            background: Item {} // Remove default background
                            
                            onAccepted: {
                                if (runnerModel.count > 0) {
                                    runnerModel.trigger(0, "", null)
                                    root.expanded = false
                                }
                            }
                            
                            Keys.onDownPressed: {
                                resultsList.forceActiveFocus()
                                if (resultsList.currentIndex < 0) resultsList.currentIndex = 0
                            }
                        }
                    }
                }
                
                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.1)
                    visible: runnerModel.count > 0
                }
                
                // Results List
                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 10
                    clip: true
                    model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                    
                    delegate: Item {
                        width: ListView.view.width
                        height: 60
                        
                        Rectangle {
                            anchors.fill: parent
                            color: mouseArea.containsMouse || resultsList.currentIndex === index ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                            radius: 8
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
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
                                        color: Qt.rgba(1, 1, 1, 0.6)
                                        font.pixelSize: 14
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
