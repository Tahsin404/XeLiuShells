// ~/.config/quickshell/modules/RightUtilityPill.qml
import QtQuick
import "../core"
import "../components"
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Effects
import "../widgets/utility"

Scope {
    id: utilityScope
    property bool isExpanded: false

    // Passively listens to the continuous bash stream
    Process {
        id: hwMonitor
        command: ["bash", "-c", "$HOME/.config/quickshell/scripts/hardware.sh"]

        // Automatically kills the bash script when you close the widget
        running: utilityScope.isExpanded

        // Quickshell's native way to read a continuous terminal stream
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(" ");
                if (parts.length === 3) {
                    GlobalState.cpuLevel = parseFloat(parts[0]);
                    GlobalState.ramLevel = parseFloat(parts[1]);
                    GlobalState.gpuLevel = parseFloat(parts[2]);
                }
            }
        }
    }

    // Triggers the script every 2.5 seconds only when the dashboard is open
    Timer {
        interval: 2500
        running: utilityScope.isExpanded
        repeat: true
        onTriggered: {
            hwMonitor.running = true;
        }
    }

    IpcHandler {
        target: "utility"
        function toggle(): void {
            utilityScope.isExpanded = !utilityScope.isExpanded;
            if (utilityScope.isExpanded) {}
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                right: true
            }
            margins.right: 10

            color: "transparent"

            // Uses the entire screen as a canvas to prevent Wayland window clipping
            implicitWidth: modelData.width
            implicitHeight: modelData.height

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 40

            focusable: utilityScope.isExpanded
            mask: Region {
                item: visiblePill
            }

            Rectangle {
                id: visiblePill
                property bool isHovered: mouseArea.containsMouse

                Component.onCompleted: {
                    Backend.init();
                }
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                width: utilityScope.isExpanded ? 360 : (isHovered ? 160 : 40)
                height: utilityScope.isExpanded ? 750 : (isHovered ? 280 : 90)

                color: Theme.bgBase
                border.width: 2
                border.color: Theme.border
                radius: Theme.radiusPill
                clip: true

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

                    // Show hand cursor when hovering to click open, but normal arrow when expanded
                    cursorShape: utilityScope.isExpanded ? Qt.ArrowCursor : Qt.PointingHandCursor

                    onClicked: {
                        if (!utilityScope.isExpanded) {
                            utilityScope.isExpanded = true;
                            visiblePill.forceActiveFocus();
                        }
                    }
                }

                Keys.onEscapePressed: event => {
                    utilityScope.isExpanded = false;
                    event.accepted = true;
                }

                // ---------------------------------------------------------
                // STATE 1 & 2: COLLAPSED AND HOVERED (With Handle)
                // ---------------------------------------------------------
                Item {
                    anchors.fill: parent

                    // Fades out the entire handle and grid when expanded
                    opacity: utilityScope.isExpanded ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    // Static Inner Pill Indicator (Handle)
                    Item {
                        id: rightHandle
                        width: 40
                        height: 90 // Locked to the collapsed height
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 12
                            height: 56
                            radius: 5
                            color: (visiblePill.isHovered ? "transparent" : Theme.accent)
                        }
                    }

                    Item {
                        anchors.right: rightHandle.right
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        anchors.topMargin: 20
                        anchors.bottomMargin: 20

                        opacity: (visiblePill.isHovered && !isExpanded) ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }

                        QuickSettingsGrid {}
                    }
                }

                // ---------------------------------------------------------
                // STATE 3: EXPANDED CONTROLS
                // ---------------------------------------------------------
                Item {
                    anchors.fill: parent
                    opacity: isExpanded ? 1 : 0
                    visible: opacity > 0

                    Column {
                        anchors.fill: parent
                        anchors.margins: 25
                        spacing: 20

                        PowerAndBattery {}
                        NotificationCenter {}
                        HardwareMonitors {}
                    }

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: isExpanded ? 150 : 0
                            }
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }
            }
        }
    }
}
