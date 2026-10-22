// ~/.config/quickshell/modules/LeftMediaPill.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../core"
import "../widgets/media"

Scope {
    id: mediaScope
    readonly property bool isExpanded: GlobalState.mediaExpanded

    IpcHandler {
        target: "media"
        function toggle(): void {
            if (GlobalState.isRecordingKeybind)
                return;
            GlobalState.mediaExpanded = !GlobalState.mediaExpanded;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pWin
            required property var modelData
            screen: modelData

            anchors {
                left: true
            }
            margins.left: 10

            color: "transparent"
            implicitWidth: modelData.width / 2
            implicitHeight: modelData.height / 2

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 40

            focusable: mediaScope.isExpanded

            HyprlandFocusGrab {
                windows: [pWin]
                active: mediaScope.isExpanded
            }

            mask: Region {
                item: visiblePill
            }

            Rectangle {
                id: visiblePill

                property bool isHovered: mouseArea.containsMouse || hardwareControls.isSliderActive

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                width: mediaScope.isExpanded ? parent.width : (isHovered ? (parent.width / 4) : 40)
                height: mediaScope.isExpanded ? parent.height : (isHovered ? (parent.height / 2) : 90)

                color: Theme.bgBase
                radius: 20
                border.width: 2
                border.color: Theme.border
                clip: true
                focus: true

                Connections {
                    target: GlobalState
                    function onMediaExpandedChanged() {
                        if (GlobalState.mediaExpanded) {
                            visiblePill.forceActiveFocus();
                        }
                    }
                }

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

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        GlobalState.mediaExpanded = !GlobalState.mediaExpanded;
                        if (GlobalState.mediaExpanded)
                            visiblePill.forceActiveFocus();
                    }
                }

                Keys.onEscapePressed: event => {
                    GlobalState.closeAllPills();
                    event.accepted = true;
                }

                // ---------------------------------------------------------
                // 1. COLLAPSED & HOVERED STATE
                // ---------------------------------------------------------
                HardwareControls {
                    id: hardwareControls
                    anchors.fill: parent
                    isExpanded: mediaScope.isExpanded
                    isHovered: visiblePill.isHovered
                }

                // ---------------------------------------------------------
                // 2. EXPANDED STATE
                // ---------------------------------------------------------
                MprisPlayer {
                    isExpanded: mediaScope.isExpanded
                }
            }
        }
    }
}
