import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import Qt.labs.folderlistmodel 2.15

PlasmoidItem {
    id: root

    property string currentHoveredUrl: ""

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
            width: 22
            height: 22
            source: "search"
            color: mouseArea.containsMouse ? "#ffffff" : "#d8d8dc"

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
        }
        return "";
    }

    function isFolderPath(query) {
        var trimmed = query.trim();
        if (trimmed === "" || trimmed === "/") return false;
        return (trimmed.startsWith("/Desktop") || trimmed.startsWith("/Downloads") || trimmed.startsWith("/Documents") || trimmed.startsWith("/Pictures") || trimmed.startsWith("/Music") || trimmed.startsWith("/Videos") || trimmed.startsWith("~"));
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
        nameFilters: []
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
                y = Math.round((screen.height - 54) / 2) - 140

                searchField.text = ""
                previewOverlay.visible = false
                searchField.forceActiveFocus()
                openAnim.restart()
            }
        }

        mainItem: Item {
            id: containerItem
            width: searchContainer.width + 40
            height: searchContainer.height + 40

            // Entrance scale + fade, macOS-style spring settle
            scale: 0.94
            opacity: 0
            transformOrigin: Item.Top

            SequentialAnimation {
                id: openAnim
                ParallelAnimation {
                    NumberAnimation { target: containerItem; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutQuad }
                    NumberAnimation { target: containerItem; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                }
            }

            // Soft ambient drop shadow beneath the whole panel (mac-style elevation)
            Kirigami.ShadowedRectangle {
                anchors.fill: searchContainer
                anchors.centerIn: undefined
                anchors.margins: -1
                x: searchContainer.x
                y: searchContainer.y
                radius: searchContainer.radius
                color: "transparent"
                visible: false
            }

            Kirigami.ShadowedRectangle {
                id: searchContainer
                anchors.centerIn: parent
                width: searchField.text === "" ? 660 : 780
                height: searchField.text === "" ? 56 : 536

                // macOS Spotlight uses ~13-14px corner radius on the pill, 16-18 expanded
                radius: searchField.text === "" ? height / 2 : 20

                // True macOS vibrancy: near-black translucent with slight warmth, not blue-tinted
                color: Qt.rgba(0.085, 0.085, 0.095, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.09)
                border.width: 1

                // Layered, softer shadow — macOS uses a large soft blur, low opacity, minimal offset
                shadow.size: 42
                shadow.color: Qt.rgba(0, 0, 0, 0.38)
                shadow.yOffset: 14
                shadow.xOffset: 0

                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
                Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
                Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

                // Faint inner hairline highlight along the top edge — glass bevel
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height * 0.5
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }

                // Extremely subtle noise-free vignette for depth
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 0.12; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.06) }
                    }
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Top Bar (Search Input)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 22
                            anchors.rightMargin: 22
                            spacing: 14

                            Kirigami.Icon {
                                source: isFolderPath(searchField.text) ? "folder" : "search"
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignVCenter
                                color: Qt.rgba(1, 1, 1, 0.55)

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // San Francisco isn't available on Linux, but Inter/SF Pro Display fallbacks read closest
                                font.family: "SF Pro Display, Inter, -apple-system, Segoe UI, sans-serif"
                                font.pixelSize: 19
                                font.weight: Font.Normal
                                font.letterSpacing: 0.1
                                color: "#f5f5f7"
                                placeholderText: "Spotlight Search"
                                placeholderTextColor: Qt.rgba(1, 1, 1, 0.38)
                                background: Item {}
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                selectionColor: Qt.rgba(0.0, 0.48, 1.0, 0.55)

                                onAccepted: {
                                    if (isFolderPath(searchField.text) && gridViewContainer.visible) {
                                        gridResults.triggerCurrent();
                                    } else if (runnerModel.count > 0) {
                                        searchResults.triggerCurrent()
                                    }
                                }

                                Keys.onSpacePressed: (event) => {
                                    if (root.currentHoveredUrl !== "") {
                                        var urlStr = root.currentHoveredUrl;
                                        var checkStr = urlStr.toLowerCase();
                                        if (checkStr.endsWith(".png") || checkStr.endsWith(".jpg") || checkStr.endsWith(".jpeg") || checkStr.endsWith(".svg") || checkStr.endsWith(".gif") || checkStr.endsWith(".webp") || checkStr.endsWith(".bmp")) {
                                            previewImage.source = urlStr;
                                            previewOverlay.visible = true;
                                            event.accepted = true;
                                            return;
                                        }
                                    }
                                    if (searchField.activeFocus) {
                                        event.accepted = false;
                                    } else if (isFolderPath(searchField.text) && gridResults.currentIndex >= 0 && gridResults.currentIndex < folderModel.count) {
                                        var fileUrl = folderModel.get(gridResults.currentIndex, "fileUrl");
                                        var isDir = folderModel.get(gridResults.currentIndex, "fileIsDir");
                                        if (!isDir && fileUrl) {
                                            previewImage.source = fileUrl;
                                            previewOverlay.visible = true;
                                            event.accepted = true;
                                        }
                                    }
                                }

                                Keys.onReleased: (event) => {
                                    if (event.key === Qt.Key_Space) {
                                        previewOverlay.visible = false;
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

                            // Subtle clear button, mac-style, only when text present
                            Rectangle {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                Layout.alignment: Qt.AlignVCenter
                                radius: 9
                                color: clearMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
                                visible: searchField.text !== ""
                                opacity: visible ? 1 : 0

                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 9
                                    color: Qt.rgba(1, 1, 1, 0.75)
                                }

                                MouseArea {
                                    id: clearMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchField.text = "";
                                        searchField.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    // Separator Line — hairline, mac-subtle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.leftMargin: 0
                        color: Qt.rgba(1, 1, 1, 0.08)
                        visible: searchField.text !== ""
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    // Grid View for Folders (/Desktop, /Documents, etc.)
                    Item {
                        id: gridViewContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 14
                        visible: isFolderPath(searchField.text)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        GridView {
                            id: gridResults
                            anchors.fill: parent
                            clip: true
                            cellWidth: 112
                            cellHeight: 108

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                width: 6
                                contentItem: Rectangle {
                                    radius: 3
                                    color: Qt.rgba(1, 1, 1, 0.25)
                                }
                                background: Item {}
                            }

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

                            Keys.onSpacePressed: (event) => {
                                var idx = gridResults.currentIndex >= 0 ? gridResults.currentIndex : 0;
                                if (idx < folderModel.count) {
                                    var fileUrl = folderModel.get(idx, "fileUrl");
                                    var isDir = folderModel.get(idx, "fileIsDir");
                                    if (!isDir && fileUrl) {
                                        previewImage.source = fileUrl;
                                        previewOverlay.visible = true;
                                        event.accepted = true;
                                    }
                                }
                            }

                            Keys.onReleased: (event) => {
                                if (event.key === Qt.Key_Space) {
                                    previewOverlay.visible = false;
                                    event.accepted = true;
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

                                property bool isSelected: gridResults.currentIndex === index
                                property bool isHovered: gridMouseArea.containsMouse

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    color: isSelected ? Qt.rgba(0.0, 0.48, 1.0, 0.85) : (isHovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                    radius: 12
                                    scale: isHovered && !isSelected ? 1.02 : 1.0

                                    Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutQuad } }
                                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        Item {
                                            Layout.preferredWidth: 46
                                            Layout.preferredHeight: 46
                                            Layout.alignment: Qt.AlignHCenter

                                            property string fileExt: typeof fileSuffix !== "undefined" ? fileSuffix.toString().toLowerCase() : ""
                                            property bool isImage: !fileIsDir && (fileExt === "png" || fileExt === "jpg" || fileExt === "jpeg" || fileExt === "svg")

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 8
                                                color: "transparent"
                                                visible: parent.isImage

                                                Image {
                                                    anchors.fill: parent
                                                    anchors.margins: 1
                                                    source: parent.parent.isImage ? fileUrl : ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    sourceSize: Qt.size(46, 46)
                                                    asynchronous: true
                                                    layer.enabled: true
                                                }
                                            }

                                            Kirigami.Icon {
                                                anchors.fill: parent
                                                source: fileIsDir ? "folder" : "document"
                                                visible: !parent.isImage
                                            }
                                        }

                                        Text {
                                            text: fileName
                                            color: "#f5f5f7"
                                            font.family: "SF Pro Text, Inter, sans-serif"
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
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            if (!fileIsDir && fileUrl) {
                                                root.currentHoveredUrl = fileUrl.toString();
                                            } else {
                                                root.currentHoveredUrl = "";
                                            }
                                        }
                                        onExited: {
                                            root.currentHoveredUrl = "";
                                        }
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
                        spacing: 1
                        visible: searchField.text !== "" && !isFolderPath(searchField.text)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 6
                            contentItem: Rectangle {
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.25)
                            }
                            background: Item {}
                        }

                        model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null

                        function triggerCurrent() {
                            var idx = currentIndex >= 0 ? currentIndex : 0;
                            if (model && model.trigger) {
                                model.trigger(idx, "", null);
                                spotlightDialog.visible = false;
                            }
                        }

                        Keys.onSpacePressed: (event) => {
                            if (currentItem && currentItem.itemUrl) {
                                var res = currentItem.itemUrl.toString();
                                var checkStr = res.toLowerCase();
                                if (checkStr.endsWith(".png") || checkStr.endsWith(".jpg") || checkStr.endsWith(".jpeg") || checkStr.endsWith(".svg") || checkStr.endsWith(".gif") || checkStr.endsWith(".webp") || checkStr.endsWith(".bmp")) {
                                    previewImage.source = res;
                                    previewOverlay.visible = true;
                                    event.accepted = true;
                                }
                            }
                        }

                        Keys.onReleased: (event) => {
                            if (event.key === Qt.Key_Space) {
                                previewOverlay.visible = false;
                                event.accepted = true;
                            }
                        }

                        Keys.onReturnPressed: triggerCurrent()
                        Keys.onEnterPressed: triggerCurrent()

                        Keys.onEscapePressed: {
                            searchField.forceActiveFocus()
                        }

                        delegate: Item {
                            width: ListView.view.width
                            height: 52

                            property string itemUrl: {
                                var urlVal = "";
                                if (model.url) urlVal = model.url.toString();
                                else if (model.fileUrl) urlVal = model.fileUrl.toString();
                                else if (model.description && (model.description.startsWith("/") || model.description.startsWith("~"))) {
                                    urlVal = "file://" + (model.description.startsWith("~") ? StandardPaths.writableLocation(StandardPaths.HomeLocation) + model.description.substring(1) : model.description);
                                }
                                return urlVal;
                            }

                            property bool isSelected: searchResults.currentIndex === index
                            property bool isHovered: listMouseArea.containsMouse

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                radius: 10
                                color: isSelected ? Qt.rgba(0.0, 0.48, 1.0, 0.85) : (isHovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                                Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Kirigami.Icon {
                                        source: model.decoration || "application-x-executable"
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: model.display || ""
                                            color: "#f5f5f7"
                                            font.family: "SF Pro Text, Inter, sans-serif"
                                            font.pixelSize: 15
                                            font.weight: Font.Normal
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: model.description || ""
                                            color: isSelected || isHovered ? Qt.rgba(1, 1, 1, 0.88) : Qt.rgba(1, 1, 1, 0.42)
                                            font.family: "SF Pro Text, Inter, sans-serif"
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                        }
                                    }

                                    // Return-to-select hint on active row, subtle mac affordance
                                    Text {
                                        text: "↵"
                                        color: Qt.rgba(1, 1, 1, 0.55)
                                        font.pixelSize: 13
                                        visible: isSelected
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: listMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        var urlVal = "";
                                        if (model.url) urlVal = model.url.toString();
                                        else if (model.fileUrl) urlVal = model.fileUrl.toString();
                                        else if (model.description && (model.description.startsWith("/") || model.description.startsWith("~"))) {
                                            urlVal = "file://" + (model.description.startsWith("~") ? StandardPaths.writableLocation(StandardPaths.HomeLocation) + model.description.substring(1) : model.description);
                                        }
                                        root.currentHoveredUrl = urlVal;
                                    }
                                    onExited: {
                                        root.currentHoveredUrl = "";
                                    }
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
                    color: Qt.rgba(0.05, 0.05, 0.06, 0.92)
                    radius: searchContainer.radius
                    visible: false
                    z: 99
                    opacity: visible ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    Image {
                        id: previewImage
                        anchors.fill: parent
                        anchors.margins: 28
                        fillMode: Image.PreserveAspectFit
                        smooth: true

                        layer.enabled: true
                    }
                }
            }
        }
    }
}
