// ~/.config/quickshell/widgets/topbar/CompactClock.qml
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "../../core"

Item {
    id: root
    width: parent.width
    height: 40
    anchors.top: parent.top
    clip: true

    property bool isExpanded: false
    property bool isHovered: false
    property bool showRunningApps: false
    property int dynamicHoverWidth: showRunningApps ? (appsView.width + 60) : (dateTimeView.width + 60)

    signal toggleExpand

    // 1. ACTIVE APP PARSER
    property var activeWin: Hyprland.activeToplevel
    property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    property string activeAppName: {
        if (!activeWin)
            return "XeLiuS";
        if (activeWin.workspace && activeWsId !== -1 && activeWin.workspace.id !== activeWsId)
            return "XeLiuS";

        var winClass = "";
        if (activeWin.lastIpcObject && activeWin.lastIpcObject["class"])
            winClass = activeWin.lastIpcObject["class"].toLowerCase();
        else if (activeWin.appId)
            winClass = activeWin.appId.toLowerCase();

        var winTitle = activeWin.title ? activeWin.title.trim() : "";
        var raw = "";

        if (winClass.includes("kitty") || winClass.includes("alacritty") || winClass.includes("wezterm") || winClass.includes("konsole"))
            raw = winTitle.split(' ')[0];
        else if (winClass) {
            raw = winClass.split('.').pop();
            raw = raw.split('-')[0];
        } else if (winTitle)
            raw = winTitle.split(' ')[0];

        raw = raw.trim();
        if (!raw || raw === "" || raw === "hyprpaper" || raw === "waybar" || raw === "quickshell")
            return "XeLiuS";
        if (raw === "~" || raw === "-" || raw === "zsh" || raw === "bash" || raw === "fish" || raw === "kitty")
            return "Terminal";

        var formatted = raw.charAt(0).toUpperCase() + raw.slice(1);
        if (formatted === "Nvim")
            return "NeoVim";
        if (formatted === "Code")
            return "VS Code";
        if (formatted.length > 10)
            return formatted.substring(0, 10) + "…";
        return formatted;
    }

    // 2. RUNNING APPS FETCHER
    ListModel {
        id: runningAppsModel
    }
    Process {
        id: fetchClientsProcess
        property string jsonBuffer: ""
        command: ["bash", "-c", "hyprctl clients -j"]
        stdout: SplitParser {
            onRead: data => {
                fetchClientsProcess.jsonBuffer += data;
            }
        }
        onExited: {
            if (jsonBuffer.length > 0) {
                try {
                    let clients = JSON.parse(jsonBuffer);
                    let uniqueApps = {};
                    runningAppsModel.clear();

                    for (let i = 0; i < clients.length; i++) {
                        let cClass = clients[i].class.toLowerCase();
                        if (cClass === "" || cClass === "quickshell" || cClass === "waybar" || cClass === "hyprpaper")
                            continue;

                        if (!uniqueApps[cClass]) {
                            uniqueApps[cClass] = true;
                            let icon = "";
                            if (cClass.includes("browser") || cClass.includes("firefox") || cClass.includes("zen") || cClass.includes("chrome"))
                                icon = "";
                            else if (cClass.includes("spotify"))
                                icon = "";
                            else if (cClass.includes("discord") || cClass.includes("telegram") || cClass.includes("zapzap"))
                                icon = "";
                            else if (cClass.includes("steam") || cClass.includes("game") || cClass.includes("heroic"))
                                icon = "";
                            else if (cClass.includes("kitty") || cClass.includes("alacritty") || cClass.includes("terminal"))
                                icon = "";
                            else if (cClass.includes("dolphin") || cClass.includes("thunar") || cClass.includes("file"))
                                icon = "";
                            else if (cClass.includes("code") || cClass.includes("vim") || cClass.includes("obsidian"))
                                icon = "";

                            runningAppsModel.append({
                                "appIcon": icon
                            });
                        }
                    }
                } catch (e) {
                    console.log("JSON Parse Error:", e);
                }
                jsonBuffer = "";
            }
        }
    }

    onIsHoveredChanged: {
        if (isHovered) {
            fetchClientsProcess.running = true;
        } else {
            if (showRunningApps) {
                showRunningApps = false;
                slideAnim.stop();
                dateTimeView.y = 0;
                dateTimeView.opacity = 1;
                appsView.y = 40;
                appsView.opacity = 0;
            }
        }
    }

    opacity: isExpanded ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    Item {
        id: dateTimeView
        width: mainRow1.implicitWidth
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        opacity: 1

        Row {
            id: mainRow1
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: root.activeAppName
                color: Theme.textMain
                font.family: Theme.fontName
                font.pixelSize: 22
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.isHovered ? 1 : 0
                width: opacity > 0 ? implicitWidth : 0
                clip: true
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }

                Text {
                    text: "•"
                    color: Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 14
                }
                Text {
                    text: GlobalState.dayString
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 14
                }
                Text {
                    text: "•"
                    color: Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 14
                }
                Text {
                    text: GlobalState.timeString
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }
    }

    Item {
        id: appsView
        width: mainRow2.implicitWidth
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        y: 40
        opacity: 0

        Row {
            id: mainRow2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Repeater {
                model: runningAppsModel
                delegate: Text {
                    text: model.appIcon
                    color: Theme.accent
                    font.family: Theme.fontName
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Timer {
        id: scrollDebounce
        interval: 350
    }

    ParallelAnimation {
        id: slideAnim
        property var targetEnter: null
        property var targetExit: null
        property int exitY: 0
        NumberAnimation {
            target: slideAnim.targetEnter
            property: "y"
            to: 0
            duration: 350
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slideAnim.targetEnter
            property: "opacity"
            to: 1
            duration: 250
        }
        NumberAnimation {
            target: slideAnim.targetExit
            property: "y"
            to: slideAnim.exitY
            duration: 350
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slideAnim.targetExit
            property: "opacity"
            to: 0
            duration: 250
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleExpand()
        onWheel: wheel => {
            if (root.isHovered && !root.isExpanded) {
                if (!scrollDebounce.running && Math.abs(wheel.angleDelta.y) > 0) {
                    var scrollUp = wheel.angleDelta.y > 0;
                    var startY = scrollUp ? 40 : -40;
                    var exitY = scrollUp ? -40 : 40;

                    if (root.showRunningApps) {
                        dateTimeView.y = startY;
                        slideAnim.targetEnter = dateTimeView;
                        slideAnim.targetExit = appsView;
                        slideAnim.exitY = exitY;
                    } else {
                        appsView.y = startY;
                        slideAnim.targetEnter = appsView;
                        slideAnim.targetExit = dateTimeView;
                        slideAnim.exitY = exitY;
                    }
                    root.showRunningApps = !root.showRunningApps;
                    slideAnim.start();
                    scrollDebounce.start();
                }
            }
        }
    }
}
