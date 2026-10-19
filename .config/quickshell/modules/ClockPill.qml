// ~/.config/quickshell/modules/ClockPill.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../core"
import "../widgets/topbar"

Scope {
    id: clockScope
    readonly property bool isExpanded: GlobalState.clockExpanded

    IpcHandler {
        target: "clock"
        function toggle(): void {
            GlobalState.clockExpanded = !GlobalState.clockExpanded;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pWin
            required property var modelData
            screen: modelData

            anchors {
                top: true
            }
            margins.top: 10

            color: "transparent"
            implicitWidth: modelData.width / 2
            implicitHeight: 700

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 45
            focusable: clockScope.isExpanded

            HyprlandFocusGrab {
                windows: [pWin]
                active: clockScope.isExpanded
            }

            mask: Region {
                item: visiblePill
            }

            Rectangle {
                id: visiblePill

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                width: clockScope.isExpanded ? (parent.width) : (compactClock.isHovered ? Math.max(350, compactClock.dynamicHoverWidth) : 190)
                height: clockScope.isExpanded ? 700 : 40

                color: Theme.bgBase
                radius: 40
                border.width: 2
                border.color: Theme.border
                clip: true
                focus: true

                Connections {
                    target: GlobalState
                    function onClockExpandedChanged() {
                        if (GlobalState.clockExpanded) {
                            visiblePill.forceActiveFocus();
                        }
                    }
                }

                Keys.onEscapePressed: event => {
                    GlobalState.closeAllPills();
                    event.accepted = true;
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

                CompactClock {
                    id: compactClock
                    isExpanded: clockScope.isExpanded

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: compactClock.isHovered = true
                        onExited: compactClock.isHovered = false
                    }

                    onToggleExpand: {
                        GlobalState.clockExpanded = !GlobalState.clockExpanded;
                        if (GlobalState.clockExpanded)
                            visiblePill.forceActiveFocus();
                    }
                }

                ExpandedCalendar {
                    isExpanded: clockScope.isExpanded
                }
            }
        }
    }
}
