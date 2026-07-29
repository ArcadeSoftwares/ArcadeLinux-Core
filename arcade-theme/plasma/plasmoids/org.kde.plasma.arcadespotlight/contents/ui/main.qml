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
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: spotlightDialog.visible = !spotlightDialog.visible
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
        runners: [
            "services", "baloosearch", "webshortcuts", "calculator", 
            "krunner_recentdocuments", "shell", "locations", "places", 
            "systemsettings", "dictionary", "appstream", "bookmarks", 
            "sessions", "powerdevil", "kill", "datetime", "spellcheck", "krunner_webshortcuts", "krunner_services"
        ]
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
                // Perfectly center the 80px pill on the screen
                y = Math.round((screen.height - 80) / 2) - 100
                
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        
        mainItem: FocusScope {
            width: 850
            height: 800
            focus: true
            
            // Invisible background clicker to close dialog when clicking outside the pill
            MouseArea {
                anchors.fill: parent
                onClicked: spotlightDialog.visible = false
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                // 1. The Search Container (Pill when empty, Expanded Window when searching)
                Kirigami.ShadowedRectangle {
                    id: searchContainer
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                    Layout.preferredWidth: searchField.text === "" ? 750 : 850
                    Layout.preferredHeight: searchField.text === "" ? 80 : 550
                    radius: searchField.text === "" ? height / 2 : 24
                    
                    // Thicker faux glassmorphism for more "blur" feel
                    color: Qt.rgba(0.18, 0.20, 0.25, 0.90)
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    border.width: 1
                    
                    shadow.size: 40
                    shadow.color: Qt.rgba(0, 0, 0, 0.7)
                    shadow.yOffset: 16
                    
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    
                    // Thicker inner gradient to simulate dense frosted glass
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.20) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.08) }
                        }
                        z: -1
                    }
                    
                    // Prevent closing when clicking the container
                    MouseArea { anchors.fill: parent; onClicked: {} }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        
                        // Top Bar (Search Input)
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 32
                                anchors.rightMargin: 32
                                spacing: 16
                                
                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    font.pixelSize: 36
                                    font.weight: Font.Light
                                    color: "#ffffff"
                                    placeholderText: "Search or Ask"
                                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.6)
                                    background: Item {}
                                    verticalAlignment: TextInput.AlignVCenter
                                    
                                    onAccepted: {
                                        if (runnerModel.count > 0) {
                                            searchResults.triggerCurrent()
                                        }
                                    }
                                    
                                    Keys.onDownPressed: {
                                        if (searchField.text !== "") {
                                            searchResults.forceActiveFocus()
                                            if (searchResults.currentIndex < 0) searchResults.currentIndex = 0
                                        }
                                    }
                                    
                                    Keys.onEscapePressed: {
                                        if (searchField.text !== "") {
                                            searchField.text = ""
                                        } else {
                                            spotlightDialog.visible = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Separator Line
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(1, 1, 1, 0.2)
                            visible: searchField.text !== ""
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        
                        // Search Results List (Only visible when typing)
                        ListView {
                            id: searchResults
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: 16
                            clip: true
                            visible: searchField.text !== ""
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                            
                            model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                            
                            function triggerCurrent() {
                                var idx = currentIndex >= 0 ? currentIndex : 0;
                                if (model && model.trigger) {
                                    model.trigger(idx, "", null);
                                    spotlightDialog.visible = false;
                                }
                            }
                            
                            Keys.onReturnPressed: triggerCurrent()
                            Keys.onEnterPressed: triggerCurrent()
                            
                            Keys.onEscapePressed: {
                                searchField.forceActiveFocus()
                            }
                            
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
                                            searchResults.currentIndex = index;
                                            searchResults.triggerCurrent();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true } // Push layout to top
            }
            Keys.onEscapePressed: spotlightDialog.visible = false
        }
    }
}
