// ~/.config/quickshell/widgets/utility/QuickSettingsGrid.qml
import QtQuick
import "../../core"
import "../../components"

Item {
    id: root
    anchors.fill: parent

    Grid {
        anchors.fill: parent
        columns: 2
        rows: 3
        spacing: 12

        property real btnWidth: (width - spacing) / 2
        property real btnHeight: (height - (spacing * 2)) / 3

        QuickButton {
            icon: ""
            iconSize: 20
            isActive: GlobalState.wifiOn
            onClicked: {
                GlobalState.wifiOn = !GlobalState.wifiOn;
                Backend.run(GlobalState.wifiOn ? "nmcli radio wifi on" : "nmcli radio wifi off");
            }
        }
        QuickButton {
            icon: ""
            isActive: GlobalState.btOn
            onClicked: {
                GlobalState.btOn = !GlobalState.btOn;
                Backend.run(GlobalState.btOn ? "bluetoothctl power on" : "bluetoothctl power off");
            }
        }
        QuickButton {
            icon: GlobalState.dndOn ? "" : ""
            iconSize: 20
            isActive: GlobalState.dndOn
            onClicked: {
                GlobalState.dndOn = !GlobalState.dndOn;
                Backend.run(GlobalState.dndOn ? "dunstctl set-paused true" : "dunstctl set-paused false");
            }
        }
        QuickButton {
            icon: GlobalState.micMuted ? "" : ""
            isActive: GlobalState.micMuted
            onClicked: {
                GlobalState.micMuted = !GlobalState.micMuted;
                Backend.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ " + (GlobalState.micMuted ? "1" : "0"));
            }
        }
        QuickButton {
            icon: GlobalState.darkTheme ? "" : ""
            isActive: GlobalState.darkTheme
            onClicked: Backend.toggleThemePolarity()
        }
        QuickButton {
            icon: ""
            isActive: GlobalState.nightLightOn
            onClicked: {
                GlobalState.nightLightOn = !GlobalState.nightLightOn;
                Backend.run(GlobalState.nightLightOn ? "wlsunset -t 4000 &" : "pkill wlsunset");
            }
        }
    }
}
