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
        // Enable Plasma & KWin background blur
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
            
            Kirigami.ShadowedRectangle {
                id: searchContainer
                anchors.fill: parent
                radius: searchField.text === "" ? height / 2 : 24
                
                // Clean macOS Spotlight dark acrylic glass (No gradients!)
                color: Qt.rgba(0.12, 0.13, 0.16, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.18)
                border.width: 1
                
                shadow.size: 36
                shadow.color: Qt.rgba(0, 0, 0, 0.45)
                shadow.yOffset: 14
                
                Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                
                width: searchField.text === "" ? 760 : 850
                height: searchField.text === "" ? 72 : 540
                
                // Subtle light top border highlight line
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: parent.radius / 2
                    anchors.rightMargin: parent.radius / 2
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
                
                MouseArea { anchors.fill: parent; onClicked: {} }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Search Bar Row
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 28
                            anchors.rightMargin: 28
                            spacing: 14
                            
                            // Glowing cursor line indicator matching macOS Spotlight
                            Rectangle {
                                Layout.preferredWidth: 2.5
                                Layout.preferredHeight: 26
                                radius: 1.25
                                color: "#60a5fa"
                                visible: searchField.text === ""
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width + 4
                                    height: parent.height + 4
                                    radius: width / 2
                                    color: "#60a5fa"
                                    opacity: 0.35
                                    z: -1
                                }
                            }

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                font.pixelSize: 26
                                font.weight: Font.Normal
                                font.family: "Sans-Serif"
                                color: "#ffffff"
                                placeholderText: "Search or Ask"
                                placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
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
                            
                            // Microphone Icon matching sportLight.png
                            Kirigami.Icon {
                                source: "audio-input-microphone"
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                color: Qt.rgba(1, 1, 1, 0.65)
                            }
                        }
                    }
                    
                    // Sleek Separator Line
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
                            if (model && model.trigger) {
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
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                radius: 12
                                
                                color: isActive ? "#007aff" : "transparent"
                                border.color: "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 14
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 10
                                        color: isActive ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            source: model.decoration || model.icon || "application-x-executable"
                                            width: 24
                                            height: 24
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: model.display || model.text || ""
                                            color: "#ffffff"
                                            font.pixelSize: 15
                                            font.weight: isActive ? Font.DemiBold : Font.Medium
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Text {
                                            text: model.description || model.subtext || ""
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

