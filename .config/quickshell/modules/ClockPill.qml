// ~/.config/quickshell/modules/ClockPill.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../widgets/topbar"

Scope {
    id: clockScope
    property bool isExpanded: false

    IpcHandler {
        target: "clock"
        function toggle(): void {
            clockScope.isExpanded = !clockScope.isExpanded;
            if (clockScope.isExpanded)
                visiblePill.forceActiveFocus();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
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

            mask: Region {
                item: visiblePill
            }

            Rectangle {
                id: visiblePill

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                // Dynamic width driven by the carousel state!
                width: clockScope.isExpanded ? (parent.width) : (compactClock.isHovered ? Math.max(350, compactClock.dynamicHoverWidth) : 190)
                height: clockScope.isExpanded ? 700 : 40

                color: Theme.bgBase
                radius: 40
                border.width: 2
                border.color: Theme.border
                clip: true
                focus: true

                Keys.onEscapePressed: event => {
                    clockScope.isExpanded = false;
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
                        clockScope.isExpanded = !clockScope.isExpanded;
                        if (clockScope.isExpanded)
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
