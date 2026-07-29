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
                x = Math.round((screen.width - mainItem.width) / 2)
                y = Math.round((screen.height - 80) / 2) - 100
                
                searchField.text = ""
                searchField.forceActiveFocus()
            }
        }
        
        mainItem: FocusScope {
            width: 850
            height: 800
            focus: true
            
            // Background click listener to close
            MouseArea {
                anchors.fill: parent
                onClicked: spotlightDialog.visible = false
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                // 1. Premium Search Container
                Kirigami.ShadowedRectangle {
                    id: searchContainer
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                    Layout.preferredWidth: searchField.text === "" ? 760 : 850
                    Layout.preferredHeight: searchField.text === "" ? 76 : 560
                    radius: searchField.text === "" ? height / 2 : 24
                    
                    // Authentic macOS Spotlight dark acrylic glass layer
                    color: Qt.rgba(0.12, 0.13, 0.16, 0.78)
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                    
                    shadow.size: 32
                    shadow.color: Qt.rgba(0, 0, 0, 0.35)
                    shadow.yOffset: 12
                    
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    
                    // Subtle light top border highlight line for glass depth
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
                        
                        // Top Bar (Search Field & Action Hints)
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 24
                                anchors.rightMargin: 24
                                spacing: 16
                                
                                // Search Icon Prefix
                                Kirigami.Icon {
                                    source: "search"
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
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
                        
                        // Sleek Separator Line with Gradient
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            visible: searchField.text !== ""
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.18) }
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
                                id: delegateItem
                                width: ListView.view.width
                                height: 64

                                property bool isSelected: searchResults.currentIndex === index
                                property bool isHovered: listMouseArea.containsMouse
                                property bool isActive: isSelected || isHovered
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    radius: 12
                                    
                                    // Authentic macOS blue highlight pill for active/selected item
                                    color: isActive ? "#007aff" : "transparent"
                                    border.color: "transparent"
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 14
                                        
                                        // App / Result Icon Container with subtle backdrop glow on active
                                        Rectangle {
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 40
                                            radius: 10
                                            color: isActive ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                source: model.decoration || "application-x-executable"
                                                width: 26
                                                height: 26
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

                                        // Enter indicator on selected item
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
                
                Item { Layout.fillHeight: true } // Push layout to top
            }
            Keys.onEscapePressed: spotlightDialog.visible = false
        }
    }
}

