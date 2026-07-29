import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    fullRepresentation: Item {}
    
    // Panel Icon
    compactRepresentation: Item {
        implicitWidth: 32
        implicitHeight: 32
        
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: "search"
            color: mouseArea.containsMouse ? "#ffffff" : "#cccccc"
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                searchDialog.visible = !searchDialog.visible
            }
        }
    }
    
    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                root.expanded = false
                searchDialog.visible = true
            }
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

    // 1. The Search Pill Dialog
    PlasmaCore.Dialog {
        id: searchDialog
        objectName: "arcadeSpotlightSearch"
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        
        width: 650
        height: 80
        
        onVisibleChanged: {
            if (visible) {
                var screen = Qt.application.screens[0]
                x = Math.round((screen.width - width) / 2)
                y = Math.round((screen.height - height) / 2) - 250 // Position higher up
                
                searchField.text = ""
                searchField.forceActiveFocus()
            }
            gridDialog.visible = visible
        }
        
        FocusScope {
            anchors.fill: parent
            focus: true
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
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
                    placeholderText: "Applications"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    background: Item {}
                    verticalAlignment: TextInput.AlignVCenter
                    
                    onAccepted: {
                        if (runnerModel.count > 0) {
                            if (searchResults.model && searchResults.model.trigger) {
                                searchResults.model.trigger(searchResults.currentIndex >= 0 ? searchResults.currentIndex : 0, "", null)
                            }
                            searchDialog.visible = false
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
                        searchDialog.visible = false
                    }
                }
            }
        }
    }

    // 2. The App Grid Dialog (follows searchDialog's visibility)
    PlasmaCore.Dialog {
        id: gridDialog
        objectName: "arcadeSpotlightGrid"
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: false // Managed by searchDialog
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        
        width: 850
        height: 550
        
        onVisibleChanged: {
            if (visible) {
                var screen = Qt.application.screens[0]
                x = Math.round((screen.width - width) / 2)
                y = searchDialog.y + searchDialog.height + 24 // Position nicely below the pill
            }
        }
        
        FocusScope {
            anchors.fill: parent
            focus: true
            
            Item {
                anchors.fill: parent
                
                // State 1: App Grid (When no search query)
                GridView {
                    id: appGrid
                    anchors.fill: parent
                    anchors.margins: 24
                    clip: true
                    cellWidth: 120
                    cellHeight: 140
                    visible: searchField.text === ""
                    model: rootModel.favoritesModel
                    
                    delegate: Item {
                        width: appGrid.cellWidth
                        height: appGrid.cellHeight
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 8
                            color: gridMouseArea.containsMouse || appGrid.currentIndex === index ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                            radius: 18
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                
                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: model.decoration || "application-x-executable"
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 64
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: model.display || ""
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                }
                            }
                            
                            MouseArea {
                                id: gridMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (appGrid.model && appGrid.model.trigger) {
                                        appGrid.model.trigger(index, "", null)
                                    }
                                    searchDialog.visible = false
                                }
                            }
                        }
                    }
                }
                
                // State 2: Search Results List (When typing)
                ListView {
                    id: searchResults
                    anchors.fill: parent
                    anchors.margins: 16
                    clip: true
                    visible: searchField.text !== ""
                    model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                    
                    delegate: Item {
                        width: ListView.view.width
                        height: 72
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 4
                            anchors.bottomMargin: 4
                            color: listMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(0.2, 0.4, 0.8, 0.85) : "transparent"
                            radius: 14
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                anchors.leftMargin: 16
                                spacing: 16
                                
                                Kirigami.Icon {
                                    source: model.decoration || "application-x-executable"
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
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
                                        color: listMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.6)
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: listMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (searchResults.model && searchResults.model.trigger) {
                                        searchResults.model.trigger(index, "", null)
                                    }
                                    searchDialog.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
