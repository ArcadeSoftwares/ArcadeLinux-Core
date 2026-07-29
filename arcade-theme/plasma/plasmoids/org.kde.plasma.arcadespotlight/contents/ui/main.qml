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
        onClicked: {
            spotlightWindow.visible = !spotlightWindow.visible
            if (spotlightWindow.visible) spotlightWindow.requestActivate()
        }
        
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
        width: 900
        height: 700
        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Popup
        visible: false
        
        x: (Screen.desktopAvailableWidth / 2) - (width / 2)
        y: (Screen.desktopAvailableHeight / 2) - (height / 2) - 50
        
        onVisibleChanged: {
            if (visible) {
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        
        Kicker.RunnerModel {
            id: runnerModel
            appletInterface: plasmoid
            query: searchField.text
            mergeResults: true
        }

        Kicker.RootModel {
            id: rootModel
            autoPopulate: false
            flat: true
            appletInterface: plasmoid
            Component.onCompleted: {
                favoritesModel.initForClient("org.kde.plasma.arcadespotlight.favorites")
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 24
            
            // 1. The Search Pill
            Rectangle {
                id: searchPill
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 650
                Layout.preferredHeight: 72
                radius: height / 2
                
                color: Qt.rgba(0.12, 0.12, 0.12, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.2)
                border.width: 1
                
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(0, 0, 0, 0.6)
                    border.width: 2
                    z: -1
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 16
                    
                    Kirigami.Icon {
                        source: "search"
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        color: Qt.rgba(1, 1, 1, 0.8)
                    }
                    
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.pixelSize: 26
                        font.weight: Font.Normal
                        color: "#ffffff"
                        placeholderText: "Applications"
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                        background: Item {}
                        verticalAlignment: TextInput.AlignVCenter
                        
                        onAccepted: {
                            if (runnerModel.count > 0) {
                                if (searchResults.model && searchResults.model.trigger) {
                                    searchResults.model.trigger(searchResults.currentIndex >= 0 ? searchResults.currentIndex : 0, "", null)
                                }
                                spotlightWindow.visible = false
                            }
                        }
                        
                        Keys.onDownPressed: {
                            if (searchField.text === "") {
                                appGrid.forceActiveFocus()
                                if (appGrid.currentIndex < 0) appGrid.currentIndex = 0
                            } else {
                                searchResults.forceActiveFocus()
                                if (searchResults.currentIndex < 0) searchResults.currentIndex = 0
                            }
                        }
                        
                        Keys.onEscapePressed: {
                            spotlightWindow.visible = false
                        }
                    }
                }
            }
            
            // 2. The Main Applications Window
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 850
                Layout.fillHeight: true
                
                color: Qt.rgba(0.12, 0.12, 0.12, 0.85)
                radius: 24
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1
                
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(0, 0, 0, 0.5)
                    border.width: 2
                    z: -1
                }
                
                // State 1: App Grid (When no search query)
                GridView {
                    id: appGrid
                    anchors.fill: parent
                    anchors.margins: 30
                    clip: true
                    cellWidth: 110
                    cellHeight: 120
                    visible: searchField.text === ""
                    model: rootModel.favoritesModel
                    
                    delegate: Item {
                        width: appGrid.cellWidth
                        height: appGrid.cellHeight
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            color: mouseArea.containsMouse || appGrid.currentIndex === index ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                            radius: 16
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                
                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: model.decoration || "application-x-executable"
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: model.display || ""
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                }
                            }
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (appGrid.model && appGrid.model.trigger) {
                                        appGrid.model.trigger(index, "", null)
                                    }
                                    spotlightWindow.visible = false
                                }
                            }
                        }
                    }
                }
                
                // State 2: Search Results List (When typing)
                ListView {
                    id: searchResults
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    visible: searchField.text !== ""
                    model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                    
                    delegate: Item {
                        width: ListView.view.width
                        height: 64
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            color: searchMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(0.2, 0.4, 0.8, 0.8) : "transparent"
                            radius: 12
                            
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
                                        color: searchMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: searchMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (searchResults.model && searchResults.model.trigger) {
                                        searchResults.model.trigger(index, "", null)
                                    }
                                    spotlightWindow.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
