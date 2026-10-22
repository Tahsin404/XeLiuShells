// ~/.config/quickshell/widgets/dmenu/ThemeSyncConfigurator.qml
import QtQuick
import QtQuick.Layouts
import "../../core"

Item {
    id: root
    anchors.fill: parent

    signal requestClose

    property int currentIndex: 0

    readonly property var syncItems: [
        {
            key: "syncKitty",
            name: "Kitty & Ranger",
            desc: "Sync terminal & Ranger colors with wallpaper"
        },
        {
            key: "syncHyprland",
            name: "Hyprland",
            desc: "Sync window borders & drop shadow colors"
        },
        {
            key: "syncGlassEffects",
            name: "Glass Effects",
            desc: "Apply 0.4 inactive opacity & blur to apps"
        },
        {
            key: "syncNeovim",
            name: "Neovim",
            desc: "Sync Neovim & Lualine statusbar palette live"
        },
        {
            key: "syncGtk",
            name: "GTK Polarity",
            desc: "Sync system GTK Dark / Light mode preference"
        }
    ]

    function toggleKey(k) {
        if (!Config.sync)
            return;
        if (k === "syncKitty")
            Config.sync.syncKitty = !Config.sync.syncKitty;
        else if (k === "syncHyprland")
            Config.sync.syncHyprland = !Config.sync.syncHyprland;
        else if (k === "syncGlassEffects")
            Config.sync.syncGlassEffects = !Config.sync.syncGlassEffects;
        else if (k === "syncNeovim")
            Config.sync.syncNeovim = !Config.sync.syncNeovim;
        else if (k === "syncGtk")
            Config.sync.syncGtk = !Config.sync.syncGtk;
        Config.save();
    }

    onVisibleChanged: {
        if (visible) {
            root.currentIndex = 0;
            keyCatcher.forceActiveFocus();
        }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onUpPressed: event => {
            let count = root.syncItems.length;
            root.currentIndex = (root.currentIndex - 1 + count) % count;
            event.accepted = true;
        }

        Keys.onDownPressed: event => {
            let count = root.syncItems.length;
            root.currentIndex = (root.currentIndex + 1) % count;
            event.accepted = true;
        }

        Keys.onReturnPressed: event => {
            root.toggleKey(root.syncItems[root.currentIndex].key);
            event.accepted = true;
        }

        Keys.onEnterPressed: event => {
            root.toggleKey(root.syncItems[root.currentIndex].key);
            event.accepted = true;
        }

        Keys.onSpacePressed: event => {
            root.toggleKey(root.syncItems[root.currentIndex].key);
            event.accepted = true;
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace) {
                GlobalState.isSyncMode = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.requestClose();
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 22
        anchors.bottomMargin: 24
        spacing: 16

        // --- HEADER BAR ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // Back Button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: backMouse.containsMouse ? Theme.bgHover : Theme.bgBase
                border.width: 1
                border.color: backMouse.containsMouse ? Theme.accent : Theme.border

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf053"
                    color: Theme.textMain
                    font.family: Theme.iconFontName
                    font.pixelSize: 14
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalState.isSyncMode = false
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: "Theme Sync"
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: "Turning a sync switch OFF freezes that app's current palette"
                    color: Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Explicit Reset Stubs Button
            Rectangle {
                Layout.preferredWidth: resetRow.implicitWidth + 28
                Layout.preferredHeight: 38
                radius: 12
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
                        text: "\uf0e2"
                        color: resetMouse.pressed ? Theme.bgDark : Theme.accent
                        font.family: Theme.iconFontName
                        font.pixelSize: 13
                    }
                    Text {
                        text: "Reset Stubs"
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
                        Backend.resetSyncedThemes();
                        keyCatcher.forceActiveFocus();
                    }
                }
            }
        }

        // --- 5 SYNC CARDS (Pill Left + Description Middle + Sliding Switch Right) ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: root.syncItems

                Rectangle {
                    id: cardRect
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.currentIndex === index
                    readonly property bool isOn: {
                        if (!Config.sync)
                            return false;
                        if (modelData.key === "syncKitty")
                            return Config.sync.syncKitty;
                        if (modelData.key === "syncHyprland")
                            return Config.sync.syncHyprland;
                        if (modelData.key === "syncGlassEffects")
                            return Config.sync.syncGlassEffects;
                        if (modelData.key === "syncNeovim")
                            return Config.sync.syncNeovim;
                        if (modelData.key === "syncGtk")
                            return Config.sync.syncGtk;
                        return false;
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: isSelected ? Theme.bgHover : Theme.bgBase
                    border.width: isOn ? 2 : (isSelected ? 1 : 0)
                    border.color: isOn ? Theme.accent : (isSelected ? Theme.border : "transparent")

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 140
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 20
                        spacing: 18

                        // 1. LEFT: Command Name Pill
                        Rectangle {
                            Layout.preferredWidth: 156
                            Layout.preferredHeight: 36
                            radius: 18
                            color: cardRect.isOn ? Theme.accent : Theme.bgDark
                            border.width: 1
                            border.color: cardRect.isOn ? Theme.accent : Theme.border

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cardRect.modelData.name
                                color: cardRect.isOn ? Theme.bgDark : Theme.textMain
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        // 2. MIDDLE: Command Description
                        Text {
                            Layout.fillWidth: true
                            text: cardRect.modelData.desc
                            color: (cardRect.isOn || cardRect.isSelected) ? Theme.textMain : Theme.textMuted
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        // 3. RIGHT: Sliding Toggle Switch
                        Rectangle {
                            id: switchTrack
                            Layout.preferredWidth: 62
                            Layout.preferredHeight: 32
                            radius: 16
                            color: cardRect.isOn ? Theme.accent : Theme.bgDark
                            border.width: 2
                            border.color: cardRect.isOn ? Theme.accent : Theme.border

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }

                            Rectangle {
                                id: switchKnob
                                width: 22
                                height: 22
                                radius: 11
                                anchors.verticalCenter: parent.verticalCenter
                                x: cardRect.isOn ? (switchTrack.width - width - 5) : 5
                                color: cardRect.isOn ? Theme.bgDark : Theme.textMuted

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 220
                                        easing.type: Easing.OutBack
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: {
                            if (root.currentIndex !== index) {
                                root.currentIndex = index;
                            }
                        }
                        onClicked: {
                            root.currentIndex = index;
                            root.toggleKey(cardRect.modelData.key);
                            keyCatcher.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
