// ~/.config/quickshell/widgets/dmenu/DmenuLayout.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import "../../core"

RowLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 15
    spacing: 15

    signal requestClose

    readonly property bool isCommandMode: searchInput.text.trim().startsWith(">")
    property bool keyboardNavActive: false
    property real lastMouseX: -1
    property real lastMouseY: -1
    property int modelRevision: 0

    // Computes the clean command/app string for whichever item is currently highlighted
    readonly property string selectedPreviewTarget: {
        let _rev = root.modelRevision;
        let idx = resultsList.currentIndex;
        if (!GlobalState.filteredAppsModel || idx < 0 || idx >= GlobalState.filteredAppsModel.count)
            return "";

        let item = GlobalState.filteredAppsModel.get(idx);
        if (!item)
            return "";

        if (item.execCmd === "__WALLPAPER_MODE__")
            return "> wallpaper";
        if (item.execCmd === "__CMD_INSTALL_PROMPT__")
            return "> install wallpaper ~/Downloads/";
        if (item.execCmd && item.execCmd.startsWith("__CMD_INSTALL_FILE__:"))
            return "> install wallpaper " + item.execCmd.substring("__CMD_INSTALL_FILE__:".length);
        if (item.execCmd === "__CMD_TOGGLE_THEME__")
            return "> toggle theme";
        if (item.execCmd === "__CMD_RELOAD_WALLPAPERS__")
            return "> reload wallpapers";

        return item.name || "";
    }

    // Computes the faded italic ghost text to display right after the user's typed text
    readonly property string ghostDisplayText: {
        let target = root.selectedPreviewTarget;
        if (target === "")
            return "";

        let typed = searchInput.text;

        if (typed === "") {
            return target;
        }

        // 1. Direct case-insensitive prefix match (e.g. "zen" -> " Browser")
        if (target.toLowerCase().startsWith(typed.toLowerCase())) {
            return target.substring(typed.length);
        }

        // 2. Command-mode prefix match that ignores spacing after '>' (e.g. ">wall" or "> wall")
        if (typed.trim().startsWith(">") && target.startsWith(">")) {
            let gtIdx = typed.indexOf(">");
            let typedAfterGt = typed.substring(gtIdx + 1);
            let typedCmdTrimmed = typedAfterGt.trimStart();
            let targetCmd = target.substring(1).trimStart();

            if (targetCmd.toLowerCase().startsWith(typedCmdTrimmed.toLowerCase())) {
                let rem = targetCmd.substring(typedCmdTrimmed.length);
                if (typedAfterGt === "" && !rem.startsWith(" ")) {
                    return " " + rem;
                }
                return rem;
            }
        }

        // 3. When navigating via arrow keys (or matching via search tags), show the selected item inline
        return "  —  " + target;
    }

    // Populates live file suggestions when the user is typing "> install wallpaper ..."
    Connections {
        target: Backend
        function onCandidateWallpapersFound(files) {
            let raw = searchInput.text.trim();
            if (!raw.toLowerCase().startsWith(">") || !GlobalState.filteredAppsModel)
                return;

            let cmdBody = raw.substring(1).trim();
            if (!cmdBody.toLowerCase().startsWith("install wallpaper"))
                return;

            GlobalState.filteredAppsModel.clear();
            let typedArg = cmdBody.substring("install wallpaper".length).trim();

            // Always show the exact path the user typed at the very top if non-empty
            if (typedArg !== "") {
                GlobalState.filteredAppsModel.append({
                    name: "Install: " + typedArg,
                    icon: "",
                    execCmd: "__CMD_INSTALL_FILE__:" + typedArg,
                    searchTags: "",
                    score: 1000000
                });
            }

            // Append matching image files from the scanned folder (e.g., ~/Downloads)
            for (let i = 0; i < files.length; i++) {
                let f = files[i].trim();
                if (f !== "" && f !== typedArg) {
                    let fname = f.split("/").pop();
                    GlobalState.filteredAppsModel.append({
                        name: fname + "  (" + f + ")",
                        icon: "",
                        execCmd: "__CMD_INSTALL_FILE__:" + f,
                        searchTags: "",
                        score: 999999 - i
                    });
                }
            }

            resultsList.currentIndex = GlobalState.filteredAppsModel.count > 0 ? 0 : -1;
            root.modelRevision++;
        }
    }

    function updateSearch(rawText) {
        if (!GlobalState.filteredAppsModel || !GlobalState.allAppsModel)
            return;
        GlobalState.filteredAppsModel.clear();

        let trimmed = rawText.trim();

        // --- 1. COMMAND MODE (Requires '>' prefix) ---
        if (trimmed.startsWith(">")) {
            let cmdQuery = trimmed.substring(1).trim();
            let cmdLower = cmdQuery.toLowerCase();

            // If typing "> install wallpaper ...", trigger live image file scan
            if (cmdLower.startsWith("install wallpaper")) {
                let arg = cmdQuery.substring("install wallpaper".length).trim();
                if (arg !== "") {
                    GlobalState.filteredAppsModel.append({
                        name: "Install: " + arg,
                        icon: "",
                        execCmd: "__CMD_INSTALL_FILE__:" + arg,
                        searchTags: "",
                        score: 1000000
                    });
                } else {
                    GlobalState.filteredAppsModel.append({
                        name: "Scanning ~/Downloads for images... (or type a path)",
                        icon: "",
                        execCmd: "__CMD_INSTALL_PROMPT__",
                        searchTags: "",
                        score: 1000000
                    });
                }
                resultsList.currentIndex = 0;
                root.modelRevision++;
                Backend.scanCandidateWallpapers(arg);
                return;
            }

            let systemCommands = [
                {
                    name: "> wallpaper  —  Open 3D Wallpaper & Theme Switcher",
                    icon: "",
                    execCmd: "__WALLPAPER_MODE__",
                    matchKey: "wallpaper theme background carousel"
                },
                {
                    name: "> install wallpaper <path>  —  Add image to Wallpaper Arsenal",
                    icon: "",
                    execCmd: "__CMD_INSTALL_PROMPT__",
                    matchKey: "install wallpaper add copy download image"
                },
                {
                    name: "> toggle theme  —  Switch Dark / Light Mode",
                    icon: "",
                    execCmd: "__CMD_TOGGLE_THEME__",
                    matchKey: "toggle theme dark light mode polarity"
                },
                {
                    name: "> reload wallpapers  —  Rescan Wallpapers & Thumbnails",
                    icon: "",
                    execCmd: "__CMD_RELOAD_WALLPAPERS__",
                    matchKey: "reload refresh wallpapers thumbnails"
                }
            ];

            for (let i = 0; i < systemCommands.length; i++) {
                let c = systemCommands[i];
                if (cmdLower === "" || c.matchKey.includes(cmdLower) || c.name.toLowerCase().includes(cmdLower)) {
                    GlobalState.filteredAppsModel.append({
                        name: c.name,
                        icon: c.icon,
                        execCmd: c.execCmd,
                        searchTags: c.matchKey,
                        score: 999999 - i
                    });
                }
            }
            resultsList.currentIndex = GlobalState.filteredAppsModel.count > 0 ? 0 : -1;
            root.modelRevision++;
            return;
        }

        // --- 2. NORMAL APP SEARCH MODE ---
        let query = trimmed.toLowerCase();
        let tempArr = [];
        for (let i = 0; i < GlobalState.allAppsModel.count; i++) {
            let app = GlobalState.allAppsModel.get(i);
            let tags = app.searchTags ? app.searchTags.toLowerCase() : "";

            if (query === "" || app.name.toLowerCase().includes(query) || tags.includes(query)) {
                tempArr.push({
                    name: app.name,
                    icon: app.icon,
                    execCmd: app.execCmd,
                    searchTags: app.searchTags,
                    score: GlobalState.historyCounts[app.name] || 0
                });
            }
        }

        tempArr.sort((a, b) => b.score - a.score);

        for (let i = 0; i < tempArr.length; i++) {
            GlobalState.filteredAppsModel.append(tempArr[i]);
        }

        resultsList.currentIndex = GlobalState.filteredAppsModel.count > 0 ? 0 : -1;
        root.modelRevision++;
        if (resultsList.currentIndex === 0) {
            resultsList.positionViewAtBeginning();
        }
    }

    function executeEntry(name, execCmd) {
        if (execCmd === "__WALLPAPER_MODE__") {
            GlobalState.isWallpaperMode = true;
            return;
        }
        if (execCmd === "__CMD_INSTALL_PROMPT__") {
            searchInput.text = "> install wallpaper ~/Downloads/";
            searchInput.cursorPosition = searchInput.text.length;
            searchInput.forceActiveFocus();
            return;
        }
        if (execCmd.startsWith("__CMD_INSTALL_FILE__:")) {
            let targetPath = execCmd.substring("__CMD_INSTALL_FILE__:".length);
            Backend.installWallpaper(targetPath);
            return;
        }
        if (execCmd === "__CMD_TOGGLE_THEME__") {
            Backend.toggleThemePolarity();
            root.requestClose();
            return;
        }
        if (execCmd === "__CMD_RELOAD_WALLPAPERS__") {
            Backend.reloadWallpapers();
            root.requestClose();
            return;
        }

        Backend.smartLaunch(name, execCmd);
        root.requestClose();
    }

    onVisibleChanged: {
        if (visible && !GlobalState.isWallpaperMode) {
            root.keyboardNavActive = false;
            root.lastMouseX = -1;
            root.lastMouseY = -1;
            searchInput.text = "";
            updateSearch("");
            searchInput.forceActiveFocus();
        }
    }

    // LEFT COLUMN: Interactive Sliding GIF Showcase
    Rectangle {
        id: gifFrame
        Layout.fillHeight: true
        Layout.preferredWidth: 300
        radius: 12
        color: Theme.bgDark
        border.color: Theme.border
        border.width: 2

        property var gifList: ["../../assets/gifs/art1.gif", "../../assets/gifs/art2.gif", "../../assets/gifs/art3.gif", "../../assets/gifs/art4.gif", "../../assets/gifs/art5.gif"]
        property int currentGifIndex: 4 // Starts on art5.gif by default
        property bool isSliding: false
        property bool isHovered: gifHoverHandler.hovered

        // Dynamically scans ~/.config/quickshell/assets/gifs for all .gif files & restores saved index
        Process {
            id: loadGifsProc
            running: true
            command: ["bash", "-c", "idx=$(cat \"$HOME/.cache/quickshell_gif_index\" 2>/dev/null || echo 4); " + "echo \"IDX:$idx\"; " + "find \"$HOME/.config/quickshell/assets/gifs\" -maxdepth 1 -type f -iname '*.gif' 2>/dev/null | sort -V"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = text.trim().split("\n");
                    let found = [];
                    let savedIdx = 4;
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i].trim();
                        if (line.startsWith("IDX:")) {
                            let parsed = parseInt(line.substring(4));
                            if (!isNaN(parsed))
                                savedIdx = parsed;
                        } else if (line !== "") {
                            found.push("file://" + line);
                        }
                    }
                    if (found.length > 0) {
                        gifFrame.gifList = found;
                        gifFrame.currentGifIndex = ((savedIdx % found.length) + found.length) % found.length;
                    }
                }
            }
        }

        function triggerGifSlide(direction) {
            if (isSliding || gifList.length <= 1)
                return;

            let count = gifList.length;
            let nextIdx = (currentGifIndex + direction + count) % count;
            slideToGifIndex(nextIdx, direction);
        }

        function slideToGifIndex(targetIdx, forcedDir) {
            if (isSliding || gifList.length <= 1 || targetIdx === currentGifIndex)
                return;

            isSliding = true;
            let dir = forcedDir !== undefined ? forcedDir : (targetIdx > currentGifIndex ? 1 : -1);

            gifSlideAnim.direction = dir;
            gifSlideAnim.nextIndex = targetIdx;
            gifSlideAnim.start();

            Backend.run("echo " + targetIdx + " > $HOME/.cache/quickshell_gif_index");
        }

        // Exact Calendar-style Sliding Window Animation (Slide + Fade Out -> Swap -> Slide + Fade In)
        SequentialAnimation {
            id: gifSlideAnim
            property int direction: 1
            property int nextIndex: 0

            ParallelAnimation {
                NumberAnimation {
                    target: gifImage
                    property: "opacity"
                    to: 0
                    duration: 150
                }
                NumberAnimation {
                    target: gifTranslate
                    property: "x"
                    to: gifSlideAnim.direction * -65
                    duration: 150
                    easing.type: Easing.InCubic
                }
            }
            ScriptAction {
                script: {
                    gifFrame.currentGifIndex = gifSlideAnim.nextIndex;
                    gifTranslate.x = gifSlideAnim.direction * 65;
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: gifImage
                    property: "opacity"
                    to: 1
                    duration: 180
                }
                NumberAnimation {
                    target: gifTranslate
                    property: "x"
                    to: 0
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            ScriptAction {
                script: {
                    gifFrame.isSliding = false;
                }
            }
        }

        HoverHandler {
            id: gifHoverHandler
        }

        Item {
            anchors.fill: parent
            anchors.margins: 2

            // 1. Offscreen Masked Container
            Item {
                id: gifContainer
                anchors.fill: parent
                visible: false
                layer.enabled: true
                clip: true

                AnimatedImage {
                    id: gifImage
                    anchors.fill: parent
                    source: gifFrame.gifList.length > 0 ? gifFrame.gifList[gifFrame.currentGifIndex] : ""
                    fillMode: Image.PreserveAspectCrop
                    transform: Translate {
                        id: gifTranslate
                        x: 0
                    }
                }
            }

            // 2. Rounded Mask Shape
            ShaderEffectSource {
                id: gifMask
                sourceItem: Rectangle {
                    width: gifContainer.width
                    height: gifContainer.height
                    radius: 10
                    color: "black"
                }
            }

            // 3. MultiEffect Rounded Output
            MultiEffect {
                anchors.fill: gifContainer
                source: gifContainer
                maskEnabled: true
                maskSource: gifMask
            }

            // Mouse Wheel Support
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    gifFrame.triggerGifSlide(wheel.angleDelta.y < 0 ? 1 : -1);
                }
            }

            // LEFT CIRCULAR SLIDE BUTTON
            Rectangle {
                id: leftArrowBtn
                width: 36
                height: 36
                radius: 18
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                color: leftArrowMouse.pressed ? Theme.accent : (leftArrowMouse.containsMouse ? Theme.bgHover : Qt.rgba(0, 0, 0, 0.55))
                border.width: 1
                border.color: leftArrowMouse.containsMouse ? Theme.accent : Theme.border

                opacity: gifFrame.isHovered ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -1
                    text: ""
                    color: leftArrowMouse.pressed ? Theme.bgDark : Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: leftArrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gifFrame.triggerGifSlide(-1)
                }
            }

            // RIGHT CIRCULAR SLIDE BUTTON
            Rectangle {
                id: rightArrowBtn
                width: 36
                height: 36
                radius: 18
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                color: rightArrowMouse.pressed ? Theme.accent : (rightArrowMouse.containsMouse ? Theme.bgHover : Qt.rgba(0, 0, 0, 0.55))
                border.width: 1
                border.color: rightArrowMouse.containsMouse ? Theme.accent : Theme.border

                opacity: gifFrame.isHovered ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    text: ""
                    color: rightArrowMouse.pressed ? Theme.bgDark : Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: rightArrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gifFrame.triggerGifSlide(1)
                }
            }

            // BOTTOM PAGINATION DOTS
            Rectangle {
                id: dotsBackdrop
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: dotsRow.implicitWidth + 16
                height: 16
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.45)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.15)
                visible: gifFrame.gifList.length > 1

                opacity: gifFrame.isHovered ? 1.0 : 0.75
                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }

                Row {
                    id: dotsRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: gifFrame.gifList.length

                        Rectangle {
                            required property int index
                            readonly property bool isCurrent: index === gifFrame.currentGifIndex

                            width: isCurrent ? 16 : 6
                            height: 6
                            radius: 3
                            color: isCurrent ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4)

                            Behavior on width {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                cursorShape: Qt.PointingHandCursor
                                onClicked: gifFrame.slideToGifIndex(index)
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 15

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: Theme.radiusBlock
            color: Theme.bgDark
            border.color: root.isCommandMode ? Theme.accent : (searchInput.activeFocus ? Theme.border : "transparent")
            border.width: root.isCommandMode ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: root.isCommandMode ? "" : ""
                    color: Theme.accent
                    font.family: Theme.fontName
                    font.pixelSize: 18
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 16
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    // Faded, italic inline ghost-text preview of the currently highlighted item
                    Text {
                        id: ghostLabel
                        x: searchInput.contentWidth
                        width: Math.max(0, searchInput.width - x)
                        height: searchInput.height
                        verticalAlignment: Text.AlignVCenter
                        text: root.ghostDisplayText
                        color: Theme.textMuted
                        opacity: 0.65
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        font.italic: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    onTextChanged: root.updateSearch(text)

                    Keys.onDownPressed: event => {
                        let count = resultsList.count;
                        if (count > 0) {
                            root.keyboardNavActive = true;
                            resultsList.currentIndex = (resultsList.currentIndex + 1) % count;
                            resultsList.positionViewAtIndex(resultsList.currentIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }

                    Keys.onUpPressed: event => {
                        let count = resultsList.count;
                        if (count > 0) {
                            root.keyboardNavActive = true;
                            resultsList.currentIndex = (resultsList.currentIndex - 1 + count) % count;
                            resultsList.positionViewAtIndex(resultsList.currentIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }

                    Keys.onTabPressed: event => {
                        if (root.selectedPreviewTarget !== "") {
                            searchInput.text = root.selectedPreviewTarget;
                            searchInput.cursorPosition = searchInput.text.length;
                        }
                        event.accepted = true;
                    }

                    Keys.onEscapePressed: event => {
                        root.requestClose();
                        event.accepted = true;
                    }

                    Keys.onReturnPressed: event => launchSelectedItem(event)
                    Keys.onEnterPressed: event => launchSelectedItem(event)

                    function launchSelectedItem(event) {
                        if (GlobalState.filteredAppsModel && GlobalState.filteredAppsModel.count > 0) {
                            let idx = resultsList.currentIndex >= 0 ? resultsList.currentIndex : 0;
                            let selectedItem = GlobalState.filteredAppsModel.get(idx);
                            root.executeEntry(selectedItem.name, selectedItem.execCmd);
                            event.accepted = true;
                            return;
                        }

                        // Fallback if the list is empty but the user typed a direct command
                        let raw = searchInput.text.trim();
                        if (raw.startsWith(">")) {
                            let cmdBody = raw.substring(1).trim();
                            let cmdLower = cmdBody.toLowerCase();

                            if (cmdLower === "wallpaper" || cmdLower === "wallpapers") {
                                GlobalState.isWallpaperMode = true;
                            } else if (cmdLower.startsWith("install wallpaper ")) {
                                let explicitPath = cmdBody.substring("install wallpaper ".length).trim();
                                if (explicitPath !== "" && !explicitPath.endsWith("/")) {
                                    Backend.installWallpaper(explicitPath);
                                }
                            }
                        }
                        event.accepted = true;
                    }
                }
            }
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: GlobalState.filteredAppsModel
            currentIndex: 0
            highlightFollowsCurrentItem: false

            delegate: Rectangle {
                id: rowRect
                width: ListView.view ? ListView.view.width : 0
                height: 50
                radius: 10

                readonly property bool isSelected: ListView.isCurrentItem

                color: isSelected ? Theme.bgHover : "transparent"
                border.width: isSelected ? 1 : 0
                border.color: isSelected ? Theme.accent : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15

                    Text {
                        text: model.icon
                        color: rowRect.isSelected ? Theme.accent : Theme.textMuted
                        font.family: Theme.fontName
                        font.pixelSize: 20
                    }
                    Text {
                        text: model.name
                        color: Theme.textMain
                        font.family: Theme.fontName
                        font.pixelSize: 14
                        font.bold: rowRect.isSelected
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.keyboardNavActive ? Qt.BlankCursor : Qt.PointingHandCursor

                    onEntered: {
                        if (!root.keyboardNavActive) {
                            resultsList.currentIndex = index;
                        }
                    }

                    onPositionChanged: mouse => {
                        let pt = mapToItem(root, mouse.x, mouse.y);
                        if (root.lastMouseX < 0 && root.lastMouseY < 0) {
                            root.lastMouseX = pt.x;
                            root.lastMouseY = pt.y;
                            if (!root.keyboardNavActive && resultsList.currentIndex !== index) {
                                resultsList.currentIndex = index;
                            }
                            return;
                        }

                        if (Math.abs(pt.x - root.lastMouseX) > 4 || Math.abs(pt.y - root.lastMouseY) > 4) {
                            root.lastMouseX = pt.x;
                            root.lastMouseY = pt.y;
                            root.keyboardNavActive = false;
                            if (resultsList.currentIndex !== index) {
                                resultsList.currentIndex = index;
                            }
                        }
                    }

                    onClicked: {
                        root.keyboardNavActive = false;
                        resultsList.currentIndex = index;
                        root.executeEntry(model.name, model.execCmd);
                    }
                }
            }
        }
    }
}
