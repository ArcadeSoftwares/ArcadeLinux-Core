import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import Qt.labs.folderlistmodel 2.15

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    fullRepresentation: Item {}

    Plasmoid.onActivated: {
        spotlightDialog.visible = !spotlightDialog.visible
    }

    Kirigami.Action {
        shortcut: "Alt+Space"
        onTriggered: spotlightDialog.visible = !spotlightDialog.visible
    }
    
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
            }
        }
    }

    // Helper functions for directory parsing and search modes
    function resolvePath(query) {
        var trimmed = query.trim();
        if (trimmed === "" || trimmed === "/") return "file:///";
        
        var homePath = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        if (trimmed === "~" || trimmed === "~/") return "file://" + homePath;
        if (trimmed.startsWith("~/")) {
            return "file://" + homePath + "/" + trimmed.substring(2);
        }
        
        if (trimmed.startsWith("/")) {
            var parts = trimmed.substring(1).split("/");
            var topDir = parts[0].toLowerCase();
            var rest = parts.slice(1).join("/");
            
            var matchedHomeFolder = "";
            if (topDir === "desktop") matchedHomeFolder = homePath + "/Desktop";
            else if (topDir === "downloads") matchedHomeFolder = homePath + "/Downloads";
            else if (topDir === "documents") matchedHomeFolder = homePath + "/Documents";
            else if (topDir === "pictures") matchedHomeFolder = homePath + "/Pictures";
            else if (topDir === "music") matchedHomeFolder = homePath + "/Music";
            else if (topDir === "videos") matchedHomeFolder = homePath + "/Videos";

            if (matchedHomeFolder !== "") {
                return "file://" + matchedHomeFolder + (rest !== "" ? "/" + rest : "");
            }
            return "file://" + trimmed;
        }
        return "file://" + homePath;
    }

    function isFolderPath(query) {
        var trimmed = query.trim();
        if (trimmed === "" || trimmed.length === 0) return false;
        return (trimmed.startsWith("/") || trimmed.startsWith("~")) && !isWildcardQuery(trimmed);
    }

    function isWildcardQuery(query) {
        var trimmed = query.trim();
        return trimmed.includes("*") || trimmed.includes("?");
    }
    
    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: plasmoid
        query: searchField.text
        mergeResults: true
        runners: [
            "services", "baloosearch", "webshortcuts", "calculator", 
            "krunner_recentdocuments", "locations", "places", 
            "systemsettings", "dictionary", "appstream", "bookmarks", 
            "sessions", "powerdevil", "kill", "datetime", "spellcheck", "krunner_webshortcuts", "krunner_services"
        ]
    }

    FolderListModel {
        id: folderModel
        folder: resolvePath(searchField.text)
        showDirs: true
        showFiles: true
        showHidden: false
        nameFilters: isWildcardQuery(searchField.text) ? [searchField.text.trim()] : []
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
                y = Math.round((screen.height - 54) / 2) - 120
                
                searchField.text = ""
                previewOverlay.visible = false
                searchField.forceActiveFocus()
            }
        }
        
        mainItem: Item {
            id: containerItem
            width: searchContainer.width + 32
            height: searchContainer.height + 32

            Kirigami.ShadowedRectangle {
                id: searchContainer
                anchors.centerIn: parent
                width: searchField.text === "" ? 640 : 760
                height: searchField.text === "" ? 54 : 520
                radius: searchField.text === "" ? height / 2 : 18
                
                // Professional dark glassmorphism palette
                color: Qt.rgba(0.10, 0.12, 0.16, 0.92)
                border.color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1
                
                shadow.size: 24
                shadow.color: Qt.rgba(0, 0, 0, 0.45)
                shadow.yOffset: 8
                
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                
                // Refined subtle top highlight gradient for premium bevel
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                        GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    z: -1
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Top Bar (Search Input)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 14
                            
                            Kirigami.Icon {
                                source: isFolderPath(searchField.text) ? "folder" : (isWildcardQuery(searchField.text) ? "system-search" : "search")
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignVCenter
                                color: Qt.rgba(1, 1, 1, 0.65)
                            }
                            
                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                font.pixelSize: 17
                                font.weight: Font.Normal
                                font.letterSpacing: 0.2
                                color: "#ffffff"
                                placeholderText: "Search apps, enter path (e.g. /Desktop), or wildcard (*.png)..."
                                placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)
                                background: Item {}
                                verticalAlignment: TextInput.AlignVCenter
                                
                                onAccepted: {
                                    if (isFolderPath(searchField.text) && gridViewContainer.visible) {
                                        gridResults.triggerCurrent();
                                    } else if (runnerModel.count > 0) {
                                        searchResults.triggerCurrent()
                                    }
                                }
                                
                                Keys.onSpacePressed: (event) => {
                                    if (isFolderPath(searchField.text) && gridResults.currentIndex >= 0 && gridResults.currentIndex < folderModel.count) {
                                        var fileUrl = folderModel.get(gridResults.currentIndex, "fileUrl");
                                        var isDir = folderModel.get(gridResults.currentIndex, "fileIsDir");
                                        if (!isDir) {
                                            previewImage.source = fileUrl;
                                            previewOverlay.visible = !previewOverlay.visible;
                                            event.accepted = true;
                                        }
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (searchField.text !== "") {
                                        if (isFolderPath(searchField.text)) {
                                            gridResults.forceActiveFocus();
                                            if (gridResults.currentIndex < 0) gridResults.currentIndex = 0;
                                        } else {
                                            searchResults.forceActiveFocus();
                                            if (searchResults.currentIndex < 0) searchResults.currentIndex = 0;
                                        }
                                    }
                                }
                                
                                Keys.onEscapePressed: {
                                    if (previewOverlay.visible) {
                                        previewOverlay.visible = false;
                                    } else if (searchField.text !== "") {
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
                        color: Qt.rgba(1, 1, 1, 0.10)
                        visible: searchField.text !== ""
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                    
                    // Grid View for Folders (/Desktop, /Documents, etc.)
                    Item {
                        id: gridViewContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 12
                        visible: isFolderPath(searchField.text)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        GridView {
                            id: gridResults
                            anchors.fill: parent
                            clip: true
                            cellWidth: 110
                            cellHeight: 105
                            model: folderModel

                            function triggerCurrent() {
                                var idx = currentIndex >= 0 ? currentIndex : 0;
                                if (idx < folderModel.count) {
                                    var fileUrl = folderModel.get(idx, "fileUrl");
                                    var isDir = folderModel.get(idx, "fileIsDir");
                                    if (isDir) {
                                        var pathStr = fileUrl.toString().replace("file://", "");
                                        searchField.text = pathStr;
                                    } else {
                                        Qt.openUrlExternally(fileUrl);
                                        spotlightDialog.visible = false;
                                    }
                                }
                            }

                            Keys.onSpacePressed: {
                                var idx = currentIndex >= 0 ? currentIndex : 0;
                                if (idx < folderModel.count) {
                                    var fileUrl = folderModel.get(idx, "fileUrl");
                                    var isDir = folderModel.get(idx, "fileIsDir");
                                    if (!isDir) {
                                        previewImage.source = fileUrl;
                                        previewOverlay.visible = true;
                                    }
                                }
                            }

                            Keys.onReleased: (event) => {
                                if (event.key === Qt.Key_Space) {
                                    previewOverlay.visible = false;
                                }
                            }

                            Keys.onSpacePressed: (event) => {
                                var idx = currentIndex >= 0 ? currentIndex : 0;
                                if (idx < folderModel.count) {
                                    var fileUrl = folderModel.get(idx, "fileUrl");
                                    var isDir = folderModel.get(idx, "fileIsDir");
                                    if (!isDir) {
                                        previewImage.source = fileUrl;
                                        previewOverlay.visible = !previewOverlay.visible;
                                        event.accepted = true;
                                    }
                                }
                            }

                            Keys.onReturnPressed: triggerCurrent()
                            Keys.onEnterPressed: triggerCurrent()
                            Keys.onEscapePressed: {
                                if (previewOverlay.visible) {
                                    previewOverlay.visible = false;
                                } else {
                                    searchField.forceActiveFocus();
                                }
                            }

                            delegate: Item {
                                width: gridResults.cellWidth
                                height: gridResults.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    color: gridMouseArea.containsMouse || gridResults.currentIndex === index ? Qt.rgba(0.2, 0.45, 0.85, 0.75) : "transparent"
                                    radius: 10

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        Kirigami.Icon {
                                            source: fileIsDir ? "folder" : (fileExtension === "png" || fileExtension === "jpg" || fileExtension === "jpeg" || fileExtension === "svg" ? fileUrl : "document")
                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 44
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Text {
                                            text: fileName
                                            color: "#ffffff"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            elide: Text.ElideMiddle
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        id: gridMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            gridResults.currentIndex = index;
                                            gridResults.triggerCurrent();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Search Results List (Standard runner search, web search & wildcard file search)
                    ListView {
                        id: searchResults
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 10
                        clip: true
                        visible: searchField.text !== "" && !isFolderPath(searchField.text)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        
                        model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
                        
                        function triggerCurrent() {
                            var idx = currentIndex >= 0 ? currentIndex : 0;
                            if (model && model.trigger) {
                                model.trigger(idx, "", null);
                                spotlightDialog.visible = false;
                            }
                        }
                        
                        Keys.onSpacePressed: (event) => {
                            var idx = currentIndex >= 0 ? currentIndex : 0;
                            if (model) {
                                var res = model.data(model.index(idx, 0), Qt.UserRole + 1); // file path/URL if present
                                if (res && (res.toString().endsWith(".png") || res.toString().endsWith(".jpg") || res.toString().endsWith(".jpeg") || res.toString().endsWith(".svg"))) {
                                    previewImage.source = res;
                                    previewOverlay.visible = !previewOverlay.visible;
                                    event.accepted = true;
                                }
                            }
                        }

                        Keys.onReturnPressed: triggerCurrent()
                        Keys.onEnterPressed: triggerCurrent()
                        
                        Keys.onEscapePressed: {
                            searchField.forceActiveFocus()
                        }
                        
                        delegate: Item {
                            width: ListView.view.width
                            height: 56
                            
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                anchors.topMargin: 2
                                anchors.bottomMargin: 2
                                color: listMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(0.2, 0.45, 0.85, 0.75) : "transparent"
                                radius: 10
                                
                                Behavior on color { ColorAnimation { duration: 120 } }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    anchors.leftMargin: 14
                                    spacing: 12
                                    
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
                                            font.pixelSize: 15
                                            font.weight: Font.Normal
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Text {
                                            text: model.description || ""
                                            color: listMouseArea.containsMouse || searchResults.currentIndex === index ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.5)
                                            font.pixelSize: 12
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

                // QuickLook Spacebar Image Preview Overlay
                Rectangle {
                    id: previewOverlay
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.85)
                    radius: searchContainer.radius
                    visible: false
                    z: 99

                    Image {
                        id: previewImage
                        anchors.fill: parent
                        anchors.margins: 24
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }
        }
    }
}

