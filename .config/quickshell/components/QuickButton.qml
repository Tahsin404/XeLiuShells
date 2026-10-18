// ~/.config/quickshell/components/QuickButton.qml
import QtQuick
import "../core"

Rectangle {
    id: root

    property string icon: "?"
    property bool isActive: false
    property int iconSize: 22
    signal clicked

    width: parent.btnWidth
    height: parent.btnHeight
    radius: Theme.radiusBlock

    // Now cleanly pulls from Theme!
    color: isActive ? Theme.accent : Theme.bgDark

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: isActive ? Theme.bgDark : Theme.textMain
        font.family: Theme.fontName
        font.pixelSize: root.iconSize
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
