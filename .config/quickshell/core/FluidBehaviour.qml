// ~/.config/quickshell/core/FluidBehavior.qml
import QtQuick

Behavior {
    id: root
    property int duration: 350
    property var easingType: Easing.OutBack

    NumberAnimation {
        duration: parent.duration
        easing.type: parent.easingType
    }
}
