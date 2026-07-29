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
        backgroundHints: PlasmaCore.Dialog.NoBackground
        
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
                radius: height / 2
                
                color: Qt.rgba(0.12, 0.14, 0.18, 0.90)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1
                
                shadow.size: 40
                shadow.color: Qt.rgba(0, 0, 0, 0.6)
                shadow.yOffset: 16
                
                // Dark translucent gradient layer matching sportLight.png
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(0.08, 0.09, 0.12, 0.95) }
                        GradientStop { position: 0.5; color: Qt.rgba(0.12, 0.14, 0.18, 0.90) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.20, 0.22, 0.28, 0.85) }
                    }
                    z: -1
                }
                
                Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                
                width: searchField.text === "" ? 760 : 850
                height: searchField.text === "" ? 72 : 540
                
                // Light inner top border glass shine
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: parent.radius / 2
                    anchors.rightMargin: parent.radius / 2
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.3)
                }
                
                MouseArea { anchors.fill: parent; onClicked: {} }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Search Bar Row (matches sportLight.png)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 32
                            anchors.rightMargin: 32
                            spacing: 14
                            
                            // Glowing cursor line indicator matching sportLight.png
                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 28
                                radius: 1.5
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
                                placeholderTextColor: Qt.rgba(1, 1, 1, 0.55)
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
                    
                    // Separator Line
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        visible: searchField.text !== ""
                        opacity: visible ? 1 : 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.20) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.02) }
                        }
                    }
                    
                    // Search Results List
                    ListView {
                        id: searchResults
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 12
                        clip: true
                        spacing: 4
                        visible: searchField.text !== ""
                        opacity: visible ? 1 : 0
                        
                        model: runnerModel
                        
                        function triggerCurrent() {
                            var idx = currentIndex >= 0 ? currentIndex : 0;
                            if (runnerModel && count > 0) {
                                runnerModel.run(idx);
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

