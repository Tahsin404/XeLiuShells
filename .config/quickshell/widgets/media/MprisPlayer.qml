// ~/.config/quickshell/widgets/media/MprisPlayer.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../../core"

Item {
    id: mprisContainer
    anchors.fill: parent
    property bool isExpanded: false

    opacity: isExpanded ? 1 : 0
    visible: opacity > 0

    property real currentPos: activePlayer ? activePlayer.position : 0
    property real seekLockoutUntil: 0

    readonly property var activePlayer: {
        if (Mpris.players.values.length === 0)
            return null;
        for (var i = 0; i < Mpris.players.values.length; i++) {
            if (Mpris.players.values[i].playbackState === MprisPlaybackState.Playing)
                return Mpris.players.values[i];
        }
        return Mpris.players.values[0];
    }

    // MPRIS Grace Period Timer
    Timer {
        interval: 100
        running: isExpanded && activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: {
            if (activePlayer) {
                var now = Date.now();
                if (now < seekLockoutUntil) {
                    currentPos = Math.min(currentPos + 0.1, activePlayer.length);
                    return;
                }
                var pos = activePlayer.position;
                var len = activePlayer.length;
                if (len > 0) {
                    if (pos >= len || pos < 0) {
                        currentPos += 0.1;
                        if (currentPos > len)
                            currentPos = len;
                    } else {
                        currentPos = pos;
                    }
                }
            }
        }
    }

    // Dynamic Blur Background
    Image {
        id: bgImage
        anchors.fill: parent
        anchors.margins: 2
        source: activePlayer ? (activePlayer.trackArtUrl || "") : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    ShaderEffectSource {
        id: bgMask
        sourceItem: Rectangle {
            width: bgImage.width
            height: bgImage.height
            radius: 18
            color: "black"
        }
    }

    MultiEffect {
        anchors.fill: bgImage
        source: bgImage
        blurEnabled: true
        blurMax: 80
        blur: 1.0
        brightness: -0.6
        saturation: 1.4
        maskEnabled: true
        maskSource: bgMask
        autoPaddingEnabled: false
    }

    Item {
        anchors.fill: parent
        anchors.margins: 35

        // LEFT: Album Art Card
        Item {
            id: albumArtCard
            width: parent.width / 2
            height: parent.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            scale: (activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing) ? 1.05 : 1.0

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Theme.bgDark
            }

            Image {
                id: albumArtImage
                anchors.fill: parent
                source: activePlayer ? (activePlayer.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            ShaderEffectSource {
                id: artMask
                sourceItem: Rectangle {
                    width: albumArtCard.width
                    height: albumArtCard.height
                    radius: 20
                    color: "black"
                }
            }
            MultiEffect {
                anchors.fill: albumArtImage
                source: albumArtImage
                maskEnabled: true
                maskSource: artMask
                autoPaddingEnabled: false
            }

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: Theme.fontName
                font.pixelSize: 60
                color: Theme.textMuted
                visible: !activePlayer || !activePlayer.trackArtUrl
            }
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: "transparent"
                border.width: 3
                border.color: Theme.accent
                antialiasing: true
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                }
            }
        }

        // RIGHT: Info, Controls, & Wavy Seekbar
        Column {
            anchors.left: albumArtCard.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 40
            spacing: 35

            Column {
                width: parent.width
                spacing: 8
                Text {
                    text: activePlayer ? ("Playing from " + activePlayer.identity) : "No Media Source"
                    color: Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    width: parent.width
                    text: activePlayer ? (activePlayer.trackTitle || "Unknown Title") : "Waiting for playback..."
                    color: Theme.textMain
                    font.family: Theme.fontName
                    font.pixelSize: 34
                    font.bold: true
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    text: activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""
                    color: Theme.accent
                    font.family: Theme.fontName
                    font.pixelSize: 20
                    elide: Text.ElideRight
                }
            }

            // Playback Controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 30
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 50
                    height: 50
                    radius: 25
                    color: prevMouse.pressed ? Theme.bgBase : Theme.bgDark
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: activePlayer && activePlayer.canGoPrevious ? Theme.accent : Theme.textMuted
                        font.family: Theme.fontName
                        font.pixelSize: 24
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (isExpanded && activePlayer)
                            activePlayer.previous()
                    }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 70
                    height: 70
                    radius: 35
                    color: playMouse.pressed ? Theme.accent : Theme.textMain
                    Text {
                        anchors.centerIn: parent
                        text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "" : ""
                        color: activePlayer ? Theme.bgDark : Theme.textMuted
                        font.family: Theme.fontName
                        font.pixelSize: 32
                    }
                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (isExpanded && activePlayer)
                            activePlayer.togglePlaying()
                    }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 50
                    height: 50
                    radius: 25
                    color: nextMouse.pressed ? Theme.bgBase : Theme.bgDark
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: activePlayer && activePlayer.canGoNext ? Theme.accent : Theme.textMuted
                        font.family: Theme.fontName
                        font.pixelSize: 24
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (isExpanded && activePlayer)
                            activePlayer.next()
                    }
                }
            }

            // Wavy Seekbar
            Item {
                id: seekbarContainer
                width: parent.width
                height: 50
                property real visualPos: mprisContainer.currentPos
                property bool isLargeJump: false

                function formatTime(val) {
                    var sec = (val > 100000) ? Math.floor(val / 1000000) : Math.floor(val);
                    if (isNaN(sec) || sec < 0)
                        return "0:00";
                    var m = Math.floor(sec / 60);
                    var s = Math.floor(sec % 60);
                    return m + ":" + (s < 10 ? "0" : "") + s;
                }

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 8
                    text: seekbarContainer.formatTime(seekbarContainer.visualPos)
                    color: Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 8
                    text: "-" + seekbarContainer.formatTime(activePlayer && activePlayer.length > 0 ? activePlayer.length - seekbarContainer.visualPos : 0)
                    color: Theme.textMuted
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }

                Connections {
                    target: mprisContainer
                    function onCurrentPosChanged() {
                        seekbarContainer.isLargeJump = Math.abs(currentPos - seekbarContainer.visualPos) > 0.5;
                        seekbarContainer.visualPos = currentPos;
                    }
                }
                Behavior on visualPos {
                    enabled: seekbarContainer.isLargeJump
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                property real progress: activePlayer && activePlayer.length > 0 ? (visualPos / activePlayer.length) : 0
                property real fillWidth: Math.max(0, Math.min(progress * width, width))

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: seekbarContainer.fillWidth
                    width: Math.max(0, seekbarContainer.width - seekbarContainer.fillWidth)
                    height: 4
                    radius: 2
                    color: Theme.bgDark
                }

                Item {
                    width: seekbarContainer.fillWidth
                    height: parent.height
                    clip: true
                    Canvas {
                        id: waveCanvas
                        width: Math.max(1, parent.width)
                        height: parent.height
                        property real phase: 0
                        onPhaseChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        Connections {
                            target: Theme
                            function onTextMainChanged() {
                                waveCanvas.requestPaint();
                            }
                        }
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var midY = height / 2;
                            function drawWave(amp, freq, phaseMultiplier, opacity, thickness) {
                                ctx.beginPath();
                                ctx.lineWidth = thickness;
                                ctx.strokeStyle = Qt.rgba(Theme.textMain.r, Theme.textMain.g, Theme.textMain.b, opacity);
                                for (var x = 0; x <= width; x += 4) {
                                    var envelope = width > 0 ? Math.sin((x / width) * Math.PI) : 0;
                                    var y = midY + Math.sin((x * freq) + (phase * phaseMultiplier)) * (amp * envelope);
                                    if (x === 0)
                                        ctx.moveTo(x, y);
                                    else
                                        ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }
                            drawWave(height / 2.5, 0.05, 1, 0.3, 2);
                            drawWave(height / 2.0, 0.03, -1, 0.6, 2);
                            drawWave(height / 3.0, 0.04, 2, 1.0, 3);
                        }
                        NumberAnimation on phase {
                            from: 0
                            to: Math.PI * 2
                            duration: 2000
                            loops: Animation.Infinite
                            running: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing && isExpanded
                        }
                    }
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    x: seekbarContainer.fillWidth - (width / 2)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function updatePosition(mouse) {
                        if (activePlayer && activePlayer.length > 0 && activePlayer.canSeek) {
                            var newPos = (Math.max(0, Math.min(mouse.x, width)) / width) * activePlayer.length;
                            activePlayer.position = newPos;
                            currentPos = newPos;
                            seekLockoutUntil = Date.now() + 1500;
                        }
                    }
                    onClicked: mouse => updatePosition(mouse)
                    onPositionChanged: mouse => {
                        if (pressed)
                            updatePosition(mouse);
                    }
                }
            }
        }
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
