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
        implicitWidth: 36
        implicitHeight: 36
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 8
            color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 20
                height: 20
                source: "search"
                color: mouseArea.containsMouse ? "#ffffff" : "#c0c4cc"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
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
        // Native KWin blur background
        backgroundHints: PlasmaCore.Dialog.BlurBackground | PlasmaCore.Dialog.NoBackground
        
        onVisibleChanged: {
            if (visible) {
                var screen = Qt.application.screens[0]
                x = Math.round((screen.width - searchContainer.width) / 2)
                y = Math.round((screen.height - 80) / 2) - 100
                
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        
        mainItem: FocusScope {
            id: containerScope
            width: searchContainer.width
            height: searchContainer.height
            focus: true
            
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            // Background click listener to close
            MouseArea {
                anchors.fill: parent
                onClicked: spotlightDialog.visible = false
            }
            
            // 1. Premium Search Container
            Kirigami.ShadowedRectangle {
                id: searchContainer
                anchors.fill: parent
                radius: searchField.text === "" ? height / 2 : 20
                
                // Translucent macOS dark acrylic background
                color: Qt.rgba(0.11, 0.12, 0.16, 0.82)
                border.color: searchField.activeFocus ? Qt.rgba(0.4, 0.6, 1.0, 0.45) : Qt.rgba(1, 1, 1, 0.18)
                border.width: 1
                
                shadow.size: 24
                shadow.color: Qt.rgba(0, 0, 0, 0.3)
                shadow.yOffset: 8
                
                Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
                
                width: searchField.text === "" ? 750 : 850
                height: searchField.text === "" ? 72 : Math.min(72 + searchResults.count * 64 + 20, 550)
                
                // Subtle top edge glass shine
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: parent.radius / 2
                    anchors.rightMargin: parent.radius / 2
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
                
                MouseArea { anchors.fill: parent; onClicked: {} }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Search Input Bar Row
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            spacing: 14
                            
                            // Search Icon Prefix
                            Kirigami.Icon {
                                source: "search"
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                color: searchField.text !== "" ? "#60a5fa" : Qt.rgba(1, 1, 1, 0.45)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            
                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                font.pixelSize: 26
                                font.weight: Font.Normal
                                font.family: "Sans-Serif"
                                color: "#ffffff"
                                placeholderText: "Search apps, files, web or commands..."
                                placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                                background: Item {}
                                verticalAlignment: TextInput.AlignVCenter
                                
                                onAccepted: {
                                    if (searchResults.count > 0) {
                                        searchResults.triggerCurrent()
                                    } else if (searchField.text.trim() !== "") {
                                        var query = encodeURIComponent(searchField.text.trim());
                                        Qt.openUrlExternally("https://www.google.com/search?q=" + query);
                                        spotlightDialog.visible = false;
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

                            // Shortcut Badge / ESC indicator
                            Rectangle {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: escText.implicitWidth + 16
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1

                                Text {
                                    id: escText
                                    anchors.centerIn: parent
                                    text: searchField.text !== "" ? "ESC to clear" : "ESC"
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                    
                    // Separator Line
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        visible: searchField.text !== ""
                        opacity: visible ? 1 : 0
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }
                    
                    // Search Results List
                    ListView {
                        id: searchResults
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 10
                        clip: true
                        spacing: 4
                        visible: searchField.text !== ""
                        opacity: visible ? 1 : 0
                        
                        model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                        
                        function triggerCurrent() {
                            var idx = currentIndex >= 0 ? currentIndex : 0;
                            if (model && model.trigger && count > 0) {
                                model.trigger(idx, "", null);
                                spotlightDialog.visible = false;
                            } else if (searchField.text.trim() !== "") {
                                var query = encodeURIComponent(searchField.text.trim());
                                Qt.openUrlExternally("https://www.google.com/search?q=" + query);
                                spotlightDialog.visible = false;
                            }
                        }
                        
                        Keys.onReturnPressed: triggerCurrent()
                        Keys.onEnterPressed: triggerCurrent()
                        
                        Keys.onEscapePressed: {
                            searchField.forceActiveFocus()
                        }
                        
                        delegate: Item {
                            id: delegateItem
                            width: ListView.view.width
                            height: 60

                            property bool isSelected: searchResults.currentIndex === index
                            property bool isHovered: listMouseArea.containsMouse
                            property bool isActive: isSelected || isHovered
                            
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                radius: 10
                                
                                // macOS style accent blue highlight pill
                                color: isActive ? "#007aff" : "transparent"
                                border.color: "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 8
                                        color: isActive ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)

                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            source: model.decoration || "application-x-executable"
                                            width: 24
                                            height: 24
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: model.display || ""
                                            color: "#ffffff"
                                            font.pixelSize: 15
                                            font.weight: isActive ? Font.DemiBold : Font.Medium
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Text {
                                            text: model.description || ""
                                            color: isActive ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.45)
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                        }
                                    }

                                    Rectangle {
                                        visible: isActive
                                        Layout.preferredHeight: 22
                                        Layout.preferredWidth: enterText.implicitWidth + 12
                                        radius: 5
                                        color: Qt.rgba(1, 1, 1, 0.15)
                                        border.color: Qt.rgba(1, 1, 1, 0.25)
                                        border.width: 1

                                        Text {
                                            id: enterText
                                            anchors.centerIn: parent
                                            text: "↵ Open"
                                            color: "#ffffff"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
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
            Keys.onEscapePressed: spotlightDialog.visible = false
        }
    }
}

