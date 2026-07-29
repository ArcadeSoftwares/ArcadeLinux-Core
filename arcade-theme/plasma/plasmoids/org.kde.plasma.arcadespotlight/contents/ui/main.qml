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

        var isWildcard = isWildcardQuery(trimmed);
        var lastSlash = trimmed.lastIndexOf("/");

        if (isWildcard && lastSlash !== -1) {
            trimmed = trimmed.substring(0, lastSlash);
            if (trimmed === "") trimmed = "/";
        } else if (isWildcard) {
            trimmed = "~";
        }

        var homePath = StandardPaths.writableLocation(StandardPaths.HomeLocation);

        if (trimmed === "~" || trimmed === "~/") return "file://" + homePath;
        if (trimmed.startsWith("~/")) {
            return "file://" + homePath + "/" + trimmed.substring(2);
        }

        if (trimmed.startsWith("/")) {
            // Drop a trailing slash before splitting so "/Desktop/" and "/Desktop/Sub/"
            // don't leave an empty final segment
            var pathToSplit = trimmed;
            if (pathToSplit.length > 1 && pathToSplit.endsWith("/")) {
                pathToSplit = pathToSplit.substring(0, pathToSplit.length - 1);
            }

            var parts = pathToSplit.substring(1).split("/");
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

        var isWildcard = isWildcardQuery(trimmed);
        if (isWildcard && trimmed.indexOf("/") === -1) {
            return true;
        }

        var lastSlash = trimmed.lastIndexOf("/");
        var checkStr = trimmed;
        if (isWildcard && lastSlash !== -1) {
            checkStr = trimmed.substring(0, lastSlash);
            if (checkStr === "") checkStr = "/";
        }

        // Strip a trailing slash so "/Desktop/" matches the same as "/Desktop"
        if (!isWildcard && checkStr.length > 1 && checkStr.endsWith("/")) {
            checkStr = checkStr.substring(0, checkStr.length - 1);
        }

        return (checkStr.startsWith("/Desktop") || checkStr.startsWith("/Downloads") || checkStr.startsWith("/Documents") || checkStr.startsWith("/Pictures") || checkStr.startsWith("/Music") || checkStr.startsWith("/Videos") || checkStr.startsWith("~"));
    }

    function isWildcardQuery(query) {
        var trimmed = query.trim();
        return trimmed.includes("*") || trimmed.includes("?");
    }

    function getWildcardFilter(query) {
        var trimmed = query.trim();
        if (!isWildcardQuery(trimmed)) return [];
        var lastSlash = trimmed.lastIndexOf("/");
        if (lastSlash !== -1) {
            return [trimmed.substring(lastSlash + 1)];
        }
        return [trimmed];
    }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: plasmoid
        query: searchField.text
        mergeResults: true
        // webshortcuts / krunner_webshortcuts removed on purpose — that runner is what
        // injects the "Search DuckDuckGo for..." fallback row. A custom "Search on web"
        // row is built manually below instead, so the label and target engine are controlled directly.
        runners: [
            "services", "baloosearch", "calculator",
            "krunner_recentdocuments", "locations", "places",
            "systemsettings", "dictionary", "appstream", "bookmarks",
            "sessions", "powerdevil", "kill", "datetime", "spellcheck", "krunner_services"
        ]
    }

    // Search engine used by the manual "Search on web" fallback row.
    // Swap this URL to change engines (e.g. Google: "https://www.google.com/search?q=")
    property string webSearchUrlBase: "https://duckduckgo.com/?q="

    FolderListModel {
        id: folderModel
        folder: resolvePath(searchField.text)
        showDirs: true
        showFiles: true
        showHidden: false
        nameFilters: getWildcardFilter(searchField.text)
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
            width: searchContainer.width + 80
            height: searchContainer.height + 80

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

            // ---- Soft layered shadow, built from stacked translucent rects instead of
            // ShadowedRectangle's shadow (which was clipping into a hard box on this compositor) ----
            Item {
                anchors.centerIn: searchContainer
                width: searchContainer.width
                height: searchContainer.height

                Repeater {
                    model: 6
                    delegate: Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + index * 10
                        height: parent.height + index * 10
                        radius: searchContainer.radius + index * 5
                        color: "transparent"
                        border.width: 6
                        border.color: Qt.rgba(0, 0, 0, 0.045 - index * 0.006)
                        y: parent.y + 3 + index * 1.5
                    }
                }
            }

            Kirigami.ShadowedRectangle {
                id: searchContainer
                anchors.centerIn: parent
                width: searchField.text === "" ? 660 : 780
                height: searchField.text === "" ? 56 : 536

                // macOS Spotlight uses ~13-14px corner radius on the pill, 16-18 expanded
                radius: searchField.text === "" ? height / 2 : 20

                // True macOS vibrancy: near-black translucent with slight warmth, not blue-tinted
                color: Qt.rgba(0.085, 0.085, 0.095, 0.86)
                border.color: Qt.rgba(1, 1, 1, 0.09)
                border.width: 1

                shadow.size: 0
                shadow.color: "transparent"

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
                                source: isFolderPath(searchField.text) ? "folder" : (isWildcardQuery(searchField.text) ? "system-search" : "search")
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
                                placeholderText: "Search"
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
                                    } else if (searchField.text !== "") {
                                        // No runner results — Enter falls through to the web search row
                                        Qt.openUrlExternally(root.webSearchUrlBase + encodeURIComponent(searchField.text));
                                        spotlightDialog.visible = false;
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

                            Text {
                                text: searchField.text !== "" && !isFolderPath(searchField.text) ? runnerModel.count + " results" : ""
                                color: Qt.rgba(1, 1, 1, 0.32)
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignVCenter
                                visible: text !== ""
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
                                            font.pixelSize: 11
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

                    // Results area: runner ListView, plus a manual "Search on web" row
                    // shown only when the runner genuinely found nothing (replaces the
                    // old DuckDuckGo webshortcuts fallback text entirely)
                    Item {
                        id: resultsArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 10
                        visible: searchField.text !== "" && !isFolderPath(searchField.text)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        property bool hasResults: runnerModel.count > 0

                        // Manual "Search on web" fallback — only row shown when hasResults is false
                        Item {
                            anchors.fill: parent
                            visible: !resultsArea.hasResults

                            Rectangle {
                                id: webSearchRow
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                height: 52
                                radius: 10
                                color: webSearchMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                                Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Kirigami.Icon {
                                        source: "internet-services"
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: "Search on web"
                                            color: "#f5f5f7"
                                            font.family: "SF Pro Text, Inter, sans-serif"
                                            font.pixelSize: 14
                                            font.weight: Font.Normal
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "\u201c" + searchField.text + "\u201d"
                                            color: Qt.rgba(1, 1, 1, 0.42)
                                            font.family: "SF Pro Text, Inter, sans-serif"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        text: "\u21b5"
                                        color: Qt.rgba(1, 1, 1, 0.55)
                                        font.pixelSize: 13
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: webSearchMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Qt.openUrlExternally(root.webSearchUrlBase + encodeURIComponent(searchField.text));
                                        spotlightDialog.visible = false;
                                    }
                                }
                            }

                            // Empty-state hint below the web search row
                            Text {
                                anchors.top: webSearchRow.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 24
                                horizontalAlignment: Text.AlignHCenter
                                text: "No local results found"
                                color: Qt.rgba(1, 1, 1, 0.28)
                                font.pixelSize: 12
                            }
                        }

                    // Search Results List (Standard runner search, web search & wildcard file search)
                    ListView {
                        id: searchResults
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 1
                        visible: resultsArea.hasResults
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
                                            font.pixelSize: 14
                                            font.weight: Font.Normal
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: model.description || ""
                                            color: isSelected || isHovered ? Qt.rgba(1, 1, 1, 0.88) : Qt.rgba(1, 1, 1, 0.42)
                                            font.family: "SF Pro Text, Inter, sans-serif"
                                            font.pixelSize: 11
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
                    } // end resultsArea
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