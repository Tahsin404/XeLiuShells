// ~/.config/quickshell/widgets/utility/NotificationCenter.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../core"

Rectangle {
    id: root
    width: parent.width
    height: 225
    radius: Theme.radiusPill
    color: Theme.bgDark
    clip: true

    // 1. LIVE FILE STREAM
    Process {
        id: liveNotifStream
        command: ["bash", "-c", "tail -F $HOME/.cache/quickshell_notifs.log"]
        running: isExpanded // Inherits from the parent pill

        stdout: SplitParser {
            onRead: data => {
                let cleanData = data.replace(/\n$/, "");
                if (cleanData.trim() === "")
                    return;

                let parts = cleanData.split("\t");
                if (parts.length >= 1) {
                    if (notifModel.count === 1 && notifModel.get(0).message === "No new notifications") {
                        notifModel.clear();
                    }

                    let app = parts[0] || "System";
                    let title = parts[1] || "";
                    let msg = parts[2] ? parts[2].replace(/<[^>]*>?/gm, '') : "";

                    let iconStr = "";
                    let appLower = app.toLowerCase();
                    if (appLower.includes("spotify"))
                        iconStr = "";
                    else if (appLower.includes("discord"))
                        iconStr = "";
                    else if (appLower.includes("mail"))
                        iconStr = "";
                    else if (appLower.includes("firefox") || appLower.includes("chrome") || appLower.includes("zen"))
                        iconStr = "";

                    notifModel.insert(0, {
                        "icon": iconStr,
                        "title": title,
                        "message": msg,
                        "time": "Now"
                    });

                    if (notifModel.count > 4) {
                        notifModel.remove(4);
                    }
                }
            }
        }
    }

    // 2. CLEAR BUTTON PROCESS
    Process {
        id: clearDunstProcess
        command: ["bash", "-c", "echo '' > $HOME/.cache/quickshell_notifs.log"]
        onExited: {
            notifModel.clear();
            notifModel.append({
                "icon": "",
                "title": "System",
                "message": "No new notifications",
                "time": ""
            });
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        // 3. HEADER
        Item {
            width: parent.width
            height: 20

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Recent Notifications"
                color: Theme.accent
                font.family: Theme.fontName
                font.pixelSize: 14
                font.bold: true
            }

            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: clearMouse.containsMouse ? Theme.error : "transparent"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: clearMouse.containsMouse ? Theme.bgDark : Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 14
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clearDunstProcess.running = true
                }
            }
        }

        // 4. LISTVIEW
        ListView {
            width: parent.width
            height: parent.height - 30
            clip: true
            spacing: 8
            model: ListModel {
                id: notifModel
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.8
                    to: 1
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                NumberAnimation {
                    property: "scale"
                    to: 0.8
                    duration: 200
                }
            }
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            delegate: Rectangle {
                width: parent.width
                height: 50
                radius: Theme.radiusBlock
                color: itemMouse.containsMouse ? Theme.bgHover : Theme.bgBase

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: isExpanded = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15
                    Text {
                        text: model.icon
                        color: Theme.accent
                        font.family: Theme.fontName
                        font.pixelSize: 18
                    }
                    Column {
                        Layout.fillWidth: true
                        Text {
                            text: model.title
                            color: Theme.textMain
                            font.bold: true
                            font.pixelSize: 13
                        }
                        Text {
                            text: model.message
                            color: Theme.textMuted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                    Text {
                        text: model.time
                        color: Theme.hardwareGpu
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
