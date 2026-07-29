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
                spotlightDialog.visible = !spotlightDialog.visible
            }
        }
    }
    
    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                root.expanded = false
                spotlightDialog.visible = true
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

    PlasmaCore.Dialog {
        id: spotlightDialog
        objectName: "arcadeSpotlightPopup"
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.NoBackground
        
        onVisibleChanged: {
            if (visible) {
                var screen = Qt.application.screens[0]
                x = Math.round((screen.width - mainItem.width) / 2)
                y = Math.round((screen.height - mainItem.height) / 2) - 50
                
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        
        mainItem: FocusScope {
            width: 850
            height: 700
            focus: true
            
            // Invisible background clicker to close dialog when clicking the gap
            MouseArea {
                anchors.fill: parent
                onClicked: spotlightDialog.visible = false
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 24
                
                // 1. The Search Pill
                Kirigami.ShadowedRectangle {
                    id: searchPill
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 650
                    Layout.preferredHeight: 72
                    radius: height / 2
                    
                    color: Qt.rgba(0.08, 0.08, 0.12, 0.75)
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                    border.width: 1
                    
                    shadow.size: 24
                    shadow.color: Qt.rgba(0, 0, 0, 0.5)
                    shadow.yOffset: 8
                    
                    // Prevent closing when clicking the pill
                    MouseArea { anchors.fill: parent; onClicked: {} }
                    
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
                            placeholderText: "Applications"
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                            background: Item {}
                            verticalAlignment: TextInput.AlignVCenter
                            
                            onAccepted: {
                                if (runnerModel.count > 0) {
                                    if (searchResults.model && searchResults.model.trigger) {
                                        searchResults.model.trigger(searchResults.currentIndex >= 0 ? searchResults.currentIndex : 0, "", null)
                                    }
                                    spotlightDialog.visible = false
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
                                spotlightDialog.visible = false
                            }
                        }
                    }
                }
                
                // 2. The Main Applications Window
                Kirigami.ShadowedRectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    color: Qt.rgba(0.08, 0.08, 0.12, 0.8)
                    radius: 24
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                    
                    shadow.size: 32
                    shadow.color: Qt.rgba(0, 0, 0, 0.6)
                    shadow.yOffset: 12
                    
                    // Prevent closing when clicking the grid background
                    MouseArea { anchors.fill: parent; onClicked: {} }
                    
                    // State 1: App Grid (When no search query)
                    GridView {
                        id: appGrid
                        anchors.fill: parent
                        anchors.margins: 30
                        clip: true
                        cellWidth: 130
                        cellHeight: 150
                        visible: searchField.text === ""
                        model: rootModel.favoritesModel
                        
                        delegate: Item {
                            width: appGrid.cellWidth
                            height: appGrid.cellHeight
                            
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 10
                                color: gridMouseArea.containsMouse || appGrid.currentIndex === index ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                radius: 20
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
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
                                        font.pixelSize: 15
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
                                        spotlightDialog.visible = false
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
                            height: 72
                            
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                color: listMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(0.2, 0.4, 0.8, 0.85) : "transparent"
                                radius: 14
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    anchors.leftMargin: 20
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
                                            color: listMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.5)
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
                                        spotlightDialog.visible = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Keys.onEscapePressed: spotlightDialog.visible = false
        }
    }
}
