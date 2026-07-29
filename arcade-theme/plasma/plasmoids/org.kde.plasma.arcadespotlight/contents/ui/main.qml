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
    
    fullRepresentation: Item {
        // We leave this empty because we spawn a true floating window instead
    }
    
    // The True Floating Spotlight Window
    Window {
        id: spotlightWindow
        width: 700
        height: runnerModel.count > 0 ? Math.min(800, 80 + (resultsList.count * 64)) : 80
        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        visible: root.expanded
        
        // Keep it perfectly centered on the screen (slightly above absolute center)
        x: (Screen.desktopAvailableWidth / 2) - (width / 2)
        y: (Screen.desktopAvailableHeight / 2) - (height / 2) - 150
        
        onVisibleChanged: {
            if (visible) {
                searchField.forceActiveFocus()
                searchField.selectAll()
            }
        }
        
        Kicker.RunnerModel {
            id: runnerModel
            appletInterface: plasmoid
            query: searchField.text
            mergeResults: true
        }

        // The unified Apple Spotlight Container
        Rectangle {
            anchors.fill: parent
            
            color: Qt.rgba(0.12, 0.12, 0.12, 0.85) // Deep translucent glass
            radius: 18
            border.color: Qt.rgba(1, 1, 1, 0.2)
            border.width: 1
            
            // Subtle Drop Shadow (faked via a background rect to avoid heavy effects)
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.6)
                border.width: 2
                z: -1
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0
                
                // 1. The Search Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 16
                        
                        Kirigami.Icon {
                            source: "search"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: Qt.rgba(1, 1, 1, 0.8)
                        }
                        
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            font.pixelSize: 32
                            font.weight: Font.Light
                            color: "#ffffff"
                            placeholderText: "Spotlight Search"
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                            background: Item {} // Remove default input styling
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
                            
                            Keys.onEscapePressed: {
                                root.expanded = false
                            }
                        }
                    }
                }
                
                // 2. The Divider Line (only when results exist)
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.15)
                    visible: runnerModel.count > 0
                }
                
                // 3. The Results List
                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                    visible: runnerModel.count > 0
                    
                    delegate: Item {
                        width: ListView.view.width
                        height: 64
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            color: mouseArea.containsMouse || resultsList.currentIndex === index ? Qt.rgba(0.2, 0.4, 0.8, 0.8) : "transparent"
                            radius: 8
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                anchors.leftMargin: 16
                                spacing: 16
                                
                                Kirigami.Icon {
                                    source: model.decoration || "application-x-executable"
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Text {
                                        text: model.display || ""
                                        color: "#ffffff"
                                        font.pixelSize: 18
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Text {
                                        text: model.description || ""
                                        color: mouseArea.containsMouse || resultsList.currentIndex === index ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.5)
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
