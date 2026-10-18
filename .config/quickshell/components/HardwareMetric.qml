// ~/.config/quickshell/components/HardwareMetric.qml
import QtQuick
import QtQuick.Effects
import "../core"

Item {
    id: root
    width: 80
    height: 190

    property string label: "CPU"
    property string icon: "?"
    property real level: 0.0
    property color accentColor: Theme.accent

    // 1. Background
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPill
        color: Theme.bgDark
    }

    // 2. The source container
    Item {
        id: fillContainer
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            width: parent.width
            height: parent.height * root.level
            anchors.bottom: parent.bottom
            color: root.accentColor
            opacity: 0.25
            Behavior on height {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.OutQuint
                }
            }
        }
    }

    // 3. The Mask Shape
    ShaderEffectSource {
        id: hwMask
        sourceItem: Rectangle {
            width: root.width
            height: root.height
            radius: Theme.radiusPill
            color: "black"
        }
    }

    // 4. The Applied Mask
    MultiEffect {
        anchors.fill: fillContainer
        source: fillContainer
        maskEnabled: true
        maskSource: hwMask
    }

    // 5. Text Overlay
    Column {
        anchors.centerIn: parent
        spacing: 12
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: Theme.textMain
            font.family: Theme.fontName
            font.pixelSize: 26
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.textMuted
            font.bold: true
            font.pixelSize: 13
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.level * 100) + "%"
            color: Theme.textMain
            font.bold: true
            font.pixelSize: 15
        }
    }
}
