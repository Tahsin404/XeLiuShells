// ~/.config/quickshell/modules/LeftMediaPill.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../widgets/media"

Scope {
    id: mediaScope
    property bool isExpanded: false

    IpcHandler {
        target: "media"
        function toggle(): void {
            mediaScope.isExpanded = !mediaScope.isExpanded;
            if (mediaScope.isExpanded) {
                visiblePill.forceActiveFocus();
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
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
            mask: Region {
                item: visiblePill
            }

            Rectangle {
                id: visiblePill

                // Passes hover state to the components
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
                        mediaScope.isExpanded = !mediaScope.isExpanded;
                        if (mediaScope.isExpanded)
                            visiblePill.forceActiveFocus();
                    }
                }

                Keys.onEscapePressed: event => {
                    mediaScope.isExpanded = false;
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
