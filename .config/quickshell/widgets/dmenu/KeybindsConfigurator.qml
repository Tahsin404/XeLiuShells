// ~/.config/quickshell/widgets/dmenu/KeybindsConfigurator.qml
import QtQuick
import QtQuick.Layouts
import "../../core"

Item {
    id: root
    anchors.fill: parent

    signal requestClose

    property string recordingTarget: ""
    property bool soloSuperPending: false

    readonly property var actionsList: [
        {
            id: "launcher",
            name: "App Launcher",
            desc: "Open the morphing workspace app & command launcher",
            icon: "",
            defaultDisp: "WIN"
        },
        {
            id: "media",
            name: "Media Pill",
            desc: "Toggle the top-left MPRIS player & audio/brightness",
            icon: "",
            defaultDisp: "F6"
        },
        {
            id: "clock",
            name: "Topbar & Calendar",
            desc: "Toggle the center clock & dynamic holiday calendar",
            icon: "",
            defaultDisp: "F7"
        },
        {
            id: "utility",
            name: "Utility Pill",
            desc: "Toggle quick settings, notifications & power menu",
            icon: "Sliders",
            iconGlyph: "",
            defaultDisp: "F8"
        }
    ]

    onVisibleChanged: {
        if (visible) {
            recordingTarget = "";
            soloSuperPending = false;
            Backend.loadKeybinds();
            keyCatcher.forceActiveFocus();
        }
    }

    // Converts a Qt.Key enum into a valid Hyprland key name
    function qtKeyToHyprKey(key) {
        if (key >= Qt.Key_F1 && key <= Qt.Key_F24)
            return "F" + (key - Qt.Key_F1 + 1);
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key);
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key);

        switch (key) {
        case Qt.Key_Space:
            return "SPACE";
        case Qt.Key_Tab:
            return "TAB";
        case Qt.Key_Return:
        case Qt.Key_Enter:
            return "RETURN";
        case Qt.Key_Period:
            return "period";
        case Qt.Key_Comma:
            return "comma";
        case Qt.Key_Slash:
            return "slash";
        case Qt.Key_Backslash:
            return "backslash";
        case Qt.Key_Minus:
            return "minus";
        case Qt.Key_Equal:
            return "equal";
        case Qt.Key_BracketLeft:
            return "bracketleft";
        case Qt.Key_BracketRight:
            return "bracketright";
        case Qt.Key_Semicolon:
            return "semicolon";
        case Qt.Key_Apostrophe:
            return "apostrophe";
        case Qt.Key_QuoteLeft:
            return "grave";
        case Qt.Key_Up:
            return "UP";
        case Qt.Key_Down:
            return "DOWN";
        case Qt.Key_Left:
            return "LEFT";
        case Qt.Key_Right:
            return "RIGHT";
        case Qt.Key_Home:
            return "HOME";
        case Qt.Key_End:
            return "END";
        case Qt.Key_PageUp:
            return "PRIOR";
        case Qt.Key_PageDown:
            return "NEXT";
        case Qt.Key_Insert:
            return "INSERT";
        case Qt.Key_Delete:
            return "DELETE";
        default:
            return "";
        }
    }

    // Keyboard Capture Item
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            // If not actively recording a keybind, allow Escape/Backspace to navigate back
            if (root.recordingTarget === "") {
                if (event.key === Qt.Key_Escape) {
                    GlobalState.isKeybindsMode = false;
                    root.requestClose();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    GlobalState.isKeybindsMode = false;
                    event.accepted = true;
                }
                return;
            }

            // Cancel recording on Escape
            if (event.key === Qt.Key_Escape) {
                root.recordingTarget = "";
                root.soloSuperPending = false;
                event.accepted = true;
                return;
            }

            // Detect solo Windows / Super key press
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
                root.soloSuperPending = true;
                event.accepted = true;
                return;
            }

            // Ignore bare Shift / Ctrl / Alt presses while waiting for the main key
            if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift || event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
                event.accepted = true;
                return;
            }

            root.soloSuperPending = false;
            let hyprKey = root.qtKeyToHyprKey(event.key);
            if (hyprKey === "") {
                event.accepted = true;
                return;
            }

            let modsList = [];
            let dispList = [];
            if (event.modifiers & Qt.MetaModifier) {
                modsList.push("SUPER");
                dispList.push("WIN");
            }
            if (event.modifiers & Qt.ControlModifier) {
                modsList.push("CTRL");
                dispList.push("CTRL");
            }
            if (event.modifiers & Qt.AltModifier) {
                modsList.push("ALT");
                dispList.push("ALT");
            }
            if (event.modifiers & Qt.ShiftModifier) {
                modsList.push("SHIFT");
                dispList.push("SHIFT");
            }

            let modsStr = modsList.join(" ");
            dispList.push(hyprKey.toUpperCase());
            let dispStr = dispList.join(" + ");

            Backend.setKeybind(root.recordingTarget, modsStr, hyprKey, dispStr);
            root.recordingTarget = "";
            event.accepted = true;
        }

        Keys.onReleased: event => {
            // If user tapped and released the Windows key by itself while recording
            if (root.recordingTarget !== "" && root.soloSuperPending && (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta)) {
                root.soloSuperPending = false;
                Backend.setKeybind(root.recordingTarget, "SUPER", "SUPER_L", "WIN");
                root.recordingTarget = "";
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // --- HEADER BAR ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Back Button
            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: backMouse.containsMouse ? Theme.bgHover : Theme.bgBase
                border.width: 1
                border.color: backMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 14
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.recordingTarget = "";
                        GlobalState.isKeybindsMode = false;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Quickshell Keybinds"
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: root.recordingTarget !== "" ? "Listening... Press any key combo (or Esc to cancel)" : "Click any shortcut pill below to record a new keybind"
                    color: root.recordingTarget !== "" ? Theme.accent : Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 11
                }
            }

            // Reset to Defaults Button
            Rectangle {
                Layout.preferredWidth: resetRow.implicitWidth + 24
                Layout.preferredHeight: 36
                radius: 10
                color: resetMouse.pressed ? Theme.accent : (resetMouse.containsMouse ? Theme.bgHover : Theme.bgBase)
                border.width: 1
                border.color: resetMouse.containsMouse ? Theme.accent : Theme.border

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: ""
                        color: resetMouse.pressed ? Theme.bgDark : Theme.accent
                        font.family: Theme.fontName
                        font.pixelSize: 13
                    }
                    Text {
                        text: "Reset Defaults"
                        color: resetMouse.pressed ? Theme.bgDark : Theme.textMain
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.recordingTarget = "";
                        Backend.resetKeybinds();
                        keyCatcher.forceActiveFocus();
                    }
                }
            }
        }

        // --- 4 KEYBIND CARDS ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Repeater {
                model: root.actionsList

                Rectangle {
                    id: bindCard
                    required property var modelData
                    readonly property bool isRecording: root.recordingTarget === modelData.id
                    readonly property string currentBadge: {
                        let map = GlobalState.keybindsMap;
                        if (map && map[modelData.id] && map[modelData.id].display)
                            return map[modelData.id].display;
                        return modelData.defaultDisp;
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: isRecording ? Theme.bgHover : (cardMouse.containsMouse ? Theme.bgHover : Theme.bgBase)
                    border.width: isRecording ? 2 : 1
                    border.color: isRecording ? Theme.accent : (cardMouse.containsMouse ? Theme.border : "transparent")

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        // Action Icon Box
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 10
                            color: Theme.bgDark
                            border.width: 1
                            border.color: bindCard.isRecording ? Theme.accent : Theme.border

                            Text {
                                anchors.centerIn: parent
                                text: bindCard.modelData.iconGlyph ? bindCard.modelData.iconGlyph : bindCard.modelData.icon
                                color: Theme.accent
                                font.family: Theme.fontName
                                font.pixelSize: 18
                            }
                        }

                        // Action Title Pill + Description (Matches Command Card Aesthetic)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                Layout.preferredWidth: actionTitleText.implicitWidth + 20
                                Layout.preferredHeight: 22
                                radius: 11
                                color: bindCard.isRecording ? Theme.accent : Theme.bgDark
                                border.width: 1
                                border.color: bindCard.isRecording ? Theme.accent : Theme.border

                                Text {
                                    id: actionTitleText
                                    anchors.centerIn: parent
                                    text: bindCard.modelData.name
                                    color: bindCard.isRecording ? Theme.bgDark : Theme.textMain
                                    font.family: Theme.fontName
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                text: bindCard.modelData.desc
                                color: Theme.textMuted
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        // Current Keybind Badge Pill
                        Rectangle {
                            Layout.preferredWidth: Math.max(88, keyText.implicitWidth + 28)
                            Layout.preferredHeight: 36
                            radius: 10
                            color: bindCard.isRecording ? Theme.accent : Theme.bgDark
                            border.width: 1
                            border.color: Theme.accent

                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: bindCard.isRecording ? "Press key..." : bindCard.currentBadge
                                color: bindCard.isRecording ? Theme.bgDark : Theme.accent
                                font.family: Theme.fontName
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (bindCard.isRecording) {
                                root.recordingTarget = "";
                            } else {
                                root.recordingTarget = bindCard.modelData.id;
                                root.soloSuperPending = false;
                            }
                            keyCatcher.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
