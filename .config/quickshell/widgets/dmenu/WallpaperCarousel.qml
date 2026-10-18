// ~/.config/quickshell/widgets/dmenu/WallpaperCarousel.qml
import QtQuick
import QtQuick.Effects
import "../../core"

Item {
    id: root
    anchors.fill: parent

    // Fixed target dimensions passed from WorkspaceNode so cards never stretch during the box morph
    property int targetWidth: 1600
    property int targetHeight: 260

    signal requestClose

    property bool activeMode: GlobalState.isWallpaperMode
    property bool keyboardNavActive: false
    property real lastMouseX: -1
    property real lastMouseY: -1

    onActiveModeChanged: {
        if (activeMode) {
            Backend.reloadWallpapers();
            root.keyboardNavActive = false;
            root.lastMouseX = -1;
            root.lastMouseY = -1;
            carouselTrack.firstVisibleIndex = 0;
            carouselTrack.currentIndex = -1;
            carouselTrack.forceActiveFocus();
            focusTimer.restart();
        }
    }

    onVisibleChanged: {
        if (visible && activeMode) {
            carouselTrack.forceActiveFocus();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: {
            if (root.activeMode) {
                carouselTrack.forceActiveFocus();
            }
        }
    }

    Item {
        id: popoutViewport
        width: root.targetWidth - 32
        height: root.targetHeight
        anchors.centerIn: parent
        clip: false

        readonly property int spacing: 20
        readonly property real cardBaseWidth: Math.floor((width - (spacing * 3)) / 4)
        readonly property real cardBaseHeight: root.targetHeight - 44
        readonly property real step: cardBaseWidth + spacing

        Item {
            id: carouselTrack
            anchors.fill: parent
            focus: true
            clip: false

            property int currentIndex: -1
            property int firstVisibleIndex: 0
            readonly property int count: cardRepeater.count

            // Smooth, fast horizontal track offset
            property real trackOffset: firstVisibleIndex * popoutViewport.step
            Behavior on trackOffset {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            function selectIndex(newIdx) {
                if (count <= 0)
                    return;
                let clamped = (newIdx + count) % count;
                currentIndex = clamped;

                if (clamped < firstVisibleIndex) {
                    firstVisibleIndex = clamped;
                } else if (clamped >= firstVisibleIndex + 4) {
                    firstVisibleIndex = clamped - 3;
                }
            }

            function activateCurrent(event) {
                if (GlobalState.wallpapersModel && currentIndex >= 0 && currentIndex < count) {
                    let item = GlobalState.wallpapersModel.get(currentIndex);
                    Backend.applyTheme(item.path);
                }
                event.accepted = true;
            }

            Keys.onLeftPressed: event => {
                if (count > 0) {
                    root.keyboardNavActive = true;
                    if (currentIndex === -1) {
                        selectIndex(firstVisibleIndex);
                    } else {
                        selectIndex(currentIndex - 1);
                    }
                }
                event.accepted = true;
            }

            Keys.onRightPressed: event => {
                if (count > 0) {
                    root.keyboardNavActive = true;
                    if (currentIndex === -1) {
                        selectIndex(firstVisibleIndex);
                    } else {
                        selectIndex(currentIndex + 1);
                    }
                }
                event.accepted = true;
            }

            Keys.onReturnPressed: event => activateCurrent(event)
            Keys.onEnterPressed: event => activateCurrent(event)

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Backspace) {
                    GlobalState.isWallpaperMode = false;
                    event.accepted = true;
                }
            }

            Keys.onEscapePressed: event => {
                root.requestClose();
                event.accepted = true;
            }

            Repeater {
                id: cardRepeater
                model: GlobalState.wallpapersModel

                delegate: Item {
                    id: cardSlot
                    width: popoutViewport.cardBaseWidth
                    height: carouselTrack.height

                    // Live physical X position along the sliding track
                    x: (index * popoutViewport.step) - carouselTrack.trackOffset

                    readonly property bool isCurrent: carouselTrack.currentIndex === index

                    // Calculates how far past the left (0) or right (3 * step) edge the card has physically slid
                    readonly property real overflowLeft: Math.max(0, -x)
                    readonly property real overflowRight: Math.max(0, x - (3 * popoutViewport.step))
                    readonly property real overflow: Math.max(overflowLeft, overflowRight)

                    // Stays 100% solid inside the bar; fades out smoothly right as it crosses the outer edges
                    opacity: Math.max(0.0, 1.0 - (overflow / (popoutViewport.cardBaseWidth * 0.35)))
                    visible: opacity > 0.01

                    // Elevate the popped-out card above the bar and sibling cards
                    z: isCurrent ? 100 : 1

                    // The 3D Pop-Out Card Container
                    Item {
                        id: popCard
                        anchors.centerIn: parent

                        width: cardSlot.isCurrent ? popoutViewport.cardBaseWidth + 28 : popoutViewport.cardBaseWidth
                        height: cardSlot.isCurrent ? root.targetHeight + 68 : popoutViewport.cardBaseHeight

                        Behavior on width {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.OutBack
                                easing.overshoot: 2.6
                            }
                        }
                        Behavior on height {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.OutBack
                                easing.overshoot: 2.6
                            }
                        }

                        transform: [
                            Scale {
                                origin.x: popCard.width / 2
                                origin.y: popCard.height / 2
                                xScale: cardSlot.isCurrent ? 1.04 : 1.0
                                yScale: cardSlot.isCurrent ? 1.04 : 1.0
                                Behavior on xScale {
                                    NumberAnimation {
                                        duration: 420
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.8
                                    }
                                }
                                Behavior on yScale {
                                    NumberAnimation {
                                        duration: 420
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.8
                                    }
                                }
                            },
                            Translate {
                                y: cardSlot.isCurrent ? -8 : 0
                                Behavior on y {
                                    NumberAnimation {
                                        duration: 420
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.6
                                    }
                                }
                            }
                        ]

                        // 1. Unclipped 360-Degree 3D GPU Drop Shadow (Inset by 2px so black never bleeds at the corners)
                        Rectangle {
                            id: shadowCaster
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: cardSlot.isCurrent ? 25 : 19
                            color: "black"
                            visible: false
                        }

                        MultiEffect {
                            width: shadowCaster.width
                            height: shadowCaster.height
                            anchors.centerIn: shadowCaster
                            autoPaddingEnabled: true
                            source: shadowCaster
                            shadowEnabled: true
                            shadowColor: cardSlot.isCurrent ? "#cc000000" : "#44000000"
                            shadowBlur: cardSlot.isCurrent ? 1.0 : 0.3
                            shadowVerticalOffset: cardSlot.isCurrent ? 14 : 4
                            shadowHorizontalOffset: 0
                            shadowScale: cardSlot.isCurrent ? 1.02 : 1.0
                        }

                        // 2. Wallpaper Image Source (Inset by 1px so its edge tucks cleanly under the vector border)
                        Item {
                            id: imgContainer
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: false
                            layer.enabled: true
                            layer.smooth: true

                            Image {
                                anchors.fill: parent
                                source: model.fileUrl
                                sourceSize.width: 640
                                sourceSize.height: 400
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: false
                                cache: true
                                smooth: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                                opacity: (carouselTrack.currentIndex !== -1 && !cardSlot.isCurrent) ? 0.35 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 180
                                    }
                                }
                            }
                        }

                        // 3. Smooth Anti-Aliased Rounded Mask
                        ShaderEffectSource {
                            id: cardMask
                            hideSource: true
                            smooth: true
                            sourceItem: Rectangle {
                                width: imgContainer.width
                                height: imgContainer.height
                                radius: cardSlot.isCurrent ? 25 : 19
                                color: "black"
                                antialiasing: true
                                visible: false
                            }
                        }

                        // 4. Masked Output (With smooth alpha threshold enabled to kill staircase edges)
                        MultiEffect {
                            anchors.fill: imgContainer
                            source: imgContainer
                            maskEnabled: true
                            maskSource: cardMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }

                        // 5. Crisp Vector 3D Rim Lighting & Border
                        Rectangle {
                            anchors.fill: parent
                            radius: cardSlot.isCurrent ? 26 : 20
                            color: "transparent"
                            antialiasing: true
                            border.width: cardSlot.isCurrent ? 3 : 1
                            border.color: cardSlot.isCurrent ? Theme.accent : Theme.bgHover
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: cardSlot.isCurrent ? 3 : 1
                            radius: cardSlot.isCurrent ? 23 : 19
                            color: "transparent"
                            antialiasing: true
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, cardSlot.isCurrent ? 0.28 : 0.06)
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: cardSlot.opacity > 0.5
                            hoverEnabled: true
                            cursorShape: root.keyboardNavActive ? Qt.BlankCursor : Qt.PointingHandCursor

                            onEntered: {
                                if (!root.keyboardNavActive) {
                                    carouselTrack.forceActiveFocus();
                                    carouselTrack.currentIndex = index;
                                }
                            }

                            onPositionChanged: mouse => {
                                let pt = mapToItem(root, mouse.x, mouse.y);
                                if (root.lastMouseX < 0 && root.lastMouseY < 0) {
                                    root.lastMouseX = pt.x;
                                    root.lastMouseY = pt.y;
                                    if (!root.keyboardNavActive && carouselTrack.currentIndex !== index) {
                                        carouselTrack.forceActiveFocus();
                                        carouselTrack.currentIndex = index;
                                    }
                                    return;
                                }

                                // Only unlock keyboard mode and select if the physical mouse actually moved on screen
                                if (Math.abs(pt.x - root.lastMouseX) > 4 || Math.abs(pt.y - root.lastMouseY) > 4) {
                                    root.lastMouseX = pt.x;
                                    root.lastMouseY = pt.y;
                                    root.keyboardNavActive = false;
                                    carouselTrack.forceActiveFocus();
                                    if (carouselTrack.currentIndex !== index) {
                                        carouselTrack.currentIndex = index;
                                    }
                                }
                            }

                            onClicked: {
                                root.keyboardNavActive = false;
                                carouselTrack.currentIndex = index;
                                Backend.applyTheme(model.path);
                            }

                            onWheel: wheel => {
                                if (carouselTrack.count > 0) {
                                    if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
                                        carouselTrack.selectIndex(carouselTrack.currentIndex === -1 ? 0 : carouselTrack.currentIndex + 1);
                                    } else if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
                                        carouselTrack.selectIndex(carouselTrack.currentIndex === -1 ? 0 : carouselTrack.currentIndex - 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
