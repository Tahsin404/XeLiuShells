// ~/.config/quickshell/widgets/media/HardwareControls.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../../core"

Item {
    id: root
    property bool isExpanded: false
    property bool isHovered: false

    // Allows the parent wrapper to know if a slider is actively being dragged
    property bool isSliderActive: volSlider.pressed || brightSlider.pressed || volSlider.hovered || brightSlider.hovered

    opacity: isExpanded ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    Item {
        id: leftHandle
        width: 40
        height: parent.height
        anchors.left: parent.left

        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 56
            radius: 5
            color: (root.isHovered ? "transparent" : Theme.accent)
        }
    }

    Item {
        anchors.left: leftHandle.right
        anchors.right: parent.right
        anchors.rightMargin: 25
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        opacity: root.isHovered ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        RowLayout {
            anchors.centerIn: parent
            height: parent.height - 30
            spacing: 40

            // VOLUME SLIDER
            ColumnLayout {
                Layout.fillHeight: true
                spacing: 15

                Slider {
                    id: volSlider
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    orientation: Qt.Vertical
                    from: 0
                    to: 1
                    topPadding: 15
                    bottomPadding: 15

                    value: GlobalState.currentVolume

                    // 1. Only listen to the true value from wpctl (via GlobalState)
                    Connections {
                        target: GlobalState
                        function onCurrentVolumeChanged() {
                            if (!volSlider.pressed) {
                                volSlider.value = GlobalState.currentVolume;
                            }
                        }
                    }

                    // 2. Use Pipewire PURELY as a tripwire for instant updates. Ignore its broken value!
                    Connections {
                        target: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
                        function onVolumeChanged() {
                            if (!volSlider.pressed) {
                                Backend.syncVolume();
                            }
                        }
                    }

                    // 3. Update the system only when YOU drag the slider
                    onValueChanged: {
                        if (volSlider.pressed) {
                            GlobalState.currentVolume = value;
                            Backend.setVolume(value);
                        }
                    }

                    // RESTORED: Thick pill background with inner groove
                    background: Rectangle {
                        x: volSlider.leftPadding + (volSlider.availableWidth - width) / 2
                        y: 0
                        implicitWidth: 46
                        implicitHeight: 150
                        width: implicitWidth
                        height: volSlider.height
                        radius: width / 2
                        color: Theme.bgDark

                        Rectangle {
                            anchors.centerIn: parent
                            width: 16
                            height: volSlider.availableHeight
                            radius: width / 2
                            color: Theme.bgBase

                            Rectangle {
                                width: parent.width
                                height: volSlider.position * parent.height
                                color: Theme.textMain
                                radius: width / 2
                                anchors.bottom: parent.bottom
                            }
                        }
                    }

                    handle: Rectangle {
                        x: volSlider.leftPadding + (volSlider.availableWidth - width) / 2
                        y: volSlider.topPadding + volSlider.visualPosition * (volSlider.availableHeight - height)
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: volSlider.pressed ? Theme.accent : Theme.textMain
                        border.color: Theme.bgDark
                        border.width: 2
                    }
                }

                // RESTORED: Bottom Icon Container
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 46
                    height: 46
                    radius: 23
                    color: Theme.bgDark
                    border.color: Theme.accent
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.textMain
                        font.family: Theme.fontName
                        font.pixelSize: 18
                    }
                }
            }

            // BRIGHTNESS SLIDER
            ColumnLayout {
                Layout.fillHeight: true
                spacing: 15
                opacity: GlobalState.hasBrightness ? 1.0 : 0.4

                Slider {
                    id: brightSlider
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    orientation: Qt.Vertical
                    from: 0
                    to: 1
                    value: GlobalState.currentBrightness
                    enabled: GlobalState.hasBrightness

                    topPadding: 15
                    bottomPadding: 15

                    onMoved: Backend.setBrightness(Math.round(value * 100) + "%")

                    // RESTORED: Thick pill background with inner groove
                    background: Rectangle {
                        x: brightSlider.leftPadding + (brightSlider.availableWidth - width) / 2
                        y: 0
                        implicitWidth: 46
                        implicitHeight: 150
                        width: implicitWidth
                        height: brightSlider.height
                        radius: width / 2
                        color: Theme.bgDark

                        Rectangle {
                            anchors.centerIn: parent
                            width: 16
                            height: brightSlider.availableHeight
                            radius: width / 2
                            color: Theme.bgBase

                            Rectangle {
                                width: parent.width
                                height: brightSlider.position * parent.height
                                color: Theme.textMain
                                radius: width / 2
                                anchors.bottom: parent.bottom
                            }
                        }
                    }

                    handle: Rectangle {
                        x: brightSlider.leftPadding + (brightSlider.availableWidth - width) / 2
                        y: brightSlider.topPadding + brightSlider.visualPosition * (brightSlider.availableHeight - height)
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: brightSlider.pressed ? Theme.accent : Theme.textMain
                        border.color: Theme.bgDark
                        border.width: 2
                    }
                }

                // RESTORED: Bottom Icon Container
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 46
                    height: 46
                    radius: 23
                    color: Theme.bgDark
                    border.color: Theme.accent
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.textMain
                        font.family: Theme.fontName
                        font.pixelSize: 18
                    }
                }
            }
        }
    }
}
