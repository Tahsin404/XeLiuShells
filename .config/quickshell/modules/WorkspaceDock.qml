import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../components" as Components

Scope {
    id: dockScope

    property int workspaceCount: 5
    property int activeMenuId: -1
    property bool isDmenuOpen: activeMenuId !== -1

    property int activeWorkspaceId: Hyprland.focusedWorkspace != null ? Hyprland.focusedWorkspace.id : 1

    IpcHandler {
        target: "dock"
        function toggleMenu(): void {
            if (dockScope.activeMenuId !== -1) {
                dockScope.activeMenuId = -1;
            } else {
                dockScope.activeMenuId = dockScope.activeWorkspaceId;
            }
        }
    }

    onActiveWorkspaceIdChanged: {
        if (activeMenuId !== -1 && activeMenuId !== activeWorkspaceId) {
            activeMenuId = -1;
        }
    }

    // Holds the Wayland click-mask open for 350ms while the pill flies back to the dock
    property bool isMaskFullScreen: false
    onIsDmenuOpenChanged: {
        if (isDmenuOpen) {
            maskCloseDelay.stop();
            isMaskFullScreen = true;
        } else {
            maskCloseDelay.restart();
        }
    }

    Timer {
        id: maskCloseDelay
        interval: 350
        onTriggered: dockScope.isMaskFullScreen = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pWin
            required property var modelData
            screen: modelData

            anchors.bottom: true
            margins.bottom: 10

            color: "transparent"
            implicitWidth: modelData.width
            implicitHeight: modelData.height

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 40
            focusable: dockScope.isDmenuOpen

            HyprlandFocusGrab {
                windows: [pWin]
                active: dockScope.isDmenuOpen

                // Bonus QoL: Hyprland natively detects when you click outside the window
                // and clears the grab, so we can use it to automatically close the dmenu!
                onCleared: dockScope.activeMenuId = -1
            }

            Region {
                id: maskClosed
                item: visibleDock
            }
            Region {
                id: maskOpen
                item: fullScreenCatcher
            }
            mask: dockScope.isMaskFullScreen ? maskOpen : maskClosed

            Row {
                id: visibleDock
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 15

                Repeater {
                    model: dockScope.workspaceCount

                    Components.WorkspaceNode {
                        workspaceId: index + 1
                        isActive: dockScope.activeWorkspaceId === workspaceId
                        isMenuOpen: dockScope.activeMenuId === workspaceId

                        screenWidth: pWin.modelData.width
                        screenHeight: pWin.modelData.height

                        // Passes the canvas down so the pill can hop into it
                        overlayParent: fullScreenCatcher

                        onMorphRequested: dockScope.activeMenuId = workspaceId
                        onRequestClose: dockScope.activeMenuId = -1
                        onNodeClicked: function (wsId) {
                            Hyprland.dispatch("workspace " + wsId);
                        }
                    }
                }
            }

            // Placed after the Row so the flying menu floats over the dock items
            Item {
                id: fullScreenCatcher
                anchors.fill: parent
                visible: dockScope.isMaskFullScreen
                z: 100

                MouseArea {
                    anchors.fill: parent
                    enabled: dockScope.isDmenuOpen
                    onClicked: dockScope.activeMenuId = -1
                }
            }
        }
    }
}
