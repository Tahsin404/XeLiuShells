// ~/.config/quickshell/components/WorkspaceNode.qml
import QtQuick
import Quickshell.Hyprland
import "../core"
import "../widgets/dmenu"

Item {
    id: nodeRoot

    property int workspaceId: 1
    property bool isActive: false
    property bool isHovered: mouseArea.containsMouse

    property int screenWidth: 1920
    property int screenHeight: 1080
    property bool isMenuOpen: false
    property Item overlayParent

    signal morphRequested
    signal nodeClicked(int wsId)
    signal requestClose

    onIsMenuOpenChanged: {
        if (!isMenuOpen) {
            GlobalState.isWallpaperMode = false;
        }
    }

    ListModel {
        id: localAllApps
    }
    ListModel {
        id: localFilteredApps
    }
    ListModel {
        id: localWallpapers
    }

    Component.onCompleted: {
        if (workspaceId === 1) {
            Backend.initDmenu(localAllApps, localFilteredApps, localWallpapers);
        }
    }

    // --- VISUAL MORPH ANIMATIONS ---
    property int baseWidth: isActive ? 60 : (isHovered ? 35 : 16)
    property int baseHeight: 30

    width: isMenuOpen ? -15 : baseWidth
    height: baseHeight

    Behavior on width {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutBack
        }
    }

    property real hoverLift: isMenuOpen ? 0 : (isActive ? 8 : (isHovered ? 4 : 0))
    Behavior on hoverLift {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutBack
        }
    }

    Rectangle {
        id: pill

        readonly property int wallpaperBarWidth: Math.max(900, nodeRoot.screenWidth - 140)
        readonly property int wallpaperBarHeight: 260

        width: nodeRoot.isMenuOpen ? (GlobalState.isWallpaperMode ? wallpaperBarWidth : 750) : nodeRoot.baseWidth
        height: nodeRoot.isMenuOpen ? (GlobalState.isWallpaperMode ? wallpaperBarHeight : 480) : 16
        radius: nodeRoot.isMenuOpen ? (GlobalState.isWallpaperMode ? 32 : 20) : 8
        color: nodeRoot.isMenuOpen ? Theme.bgDark : (nodeRoot.isActive ? Theme.textMain : Theme.textMuted)

        border.width: nodeRoot.isMenuOpen ? 2 : 0
        border.color: nodeRoot.isMenuOpen ? Theme.bgHover : "transparent"

        // Unclips when in Wallpaper Mode so the 3D popped-out card bursts past the top and bottom borders!
        clip: nodeRoot.isMenuOpen ? !GlobalState.isWallpaperMode : true

        x: 0
        y: 14
        transform: Translate {
            y: -nodeRoot.hoverLift
        }

        states: [
            State {
                name: "resting"
                when: !nodeRoot.isMenuOpen
                ParentChange {
                    target: pill
                    parent: nodeRoot
                    x: 0
                    y: 14
                }
            },
            State {
                name: "morphed"
                when: nodeRoot.isMenuOpen && !GlobalState.isWallpaperMode
                ParentChange {
                    target: pill
                    parent: nodeRoot.overlayParent
                    x: nodeRoot.screenWidth / 2 - 375
                    y: nodeRoot.screenHeight / 2 - 240
                }
            },
            State {
                name: "wallpaper"
                when: nodeRoot.isMenuOpen && GlobalState.isWallpaperMode
                ParentChange {
                    target: pill
                    parent: nodeRoot.overlayParent
                    x: (nodeRoot.screenWidth - pill.wallpaperBarWidth) / 2
                    y: (nodeRoot.screenHeight - pill.wallpaperBarHeight) / 2
                }
            }
        ]

        transitions: [
            Transition {
                from: "resting"
                to: "morphed"
                ParentAnimation {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            },
            Transition {
                from: "morphed,wallpaper"
                to: "resting"
                ParentAnimation {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            },
            Transition {
                from: "morphed"
                to: "wallpaper"
                NumberAnimation {
                    properties: "x,y"
                    duration: 350
                    easing.type: Easing.OutBack
                }
            },
            Transition {
                from: "wallpaper"
                to: "morphed"
                NumberAnimation {
                    properties: "x,y"
                    duration: 350
                    easing.type: Easing.OutBack
                }
            }
        ]

        Behavior on width {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 250
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: 250
            }
        }

        // --- STAGE 1: THE MODULAR TWO-PANE APP LAUNCHER ---
        Item {
            anchors.fill: parent
            opacity: (nodeRoot.isMenuOpen && !GlobalState.isWallpaperMode) ? 1 : 0
            visible: opacity > 0
            clip: true

            DmenuLayout {
                onRequestClose: nodeRoot.requestClose()
            }

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: (nodeRoot.isMenuOpen && !GlobalState.isWallpaperMode) ? 150 : 0
                    }
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }

        // --- STAGE 2: THE 3D POP-OUT WALLPAPER CAROUSEL ---
        Item {
            anchors.fill: parent
            opacity: (nodeRoot.isMenuOpen && GlobalState.isWallpaperMode) ? 1 : 0
            visible: opacity > 0
            clip: false

            WallpaperCarousel {
                targetWidth: pill.wallpaperBarWidth
                targetHeight: pill.wallpaperBarHeight
                onRequestClose: nodeRoot.requestClose()
            }

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: (nodeRoot.isMenuOpen && GlobalState.isWallpaperMode) ? 120 : 0
                    }
                    NumberAnimation {
                        duration: 220
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        width: nodeRoot.baseWidth
        height: nodeRoot.baseHeight
        x: 0
        y: 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !nodeRoot.isMenuOpen

        onClicked: {
            if (nodeRoot.isActive)
                nodeRoot.morphRequested();
            else
                nodeRoot.nodeClicked(nodeRoot.workspaceId);
        }
    }
}
