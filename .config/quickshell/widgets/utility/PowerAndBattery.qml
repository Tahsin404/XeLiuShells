import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../core"

Column {
    id: root
    width: parent.width
    spacing: 20

    Rectangle {
        width: parent.width
        height: 180
        radius: Theme.radiusPill
        color: Theme.bgDark

        GridLayout {
            anchors.fill: parent
            anchors.margins: 12
            columns: 3
            rows: 3
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: [
                    { icon: "", name: "Lock Screen", hColor: Theme.accent, cmd: "hyprlock" },
                    { icon: "", name: "Sleep", hColor: Theme.accent, cmd: "systemctl suspend" },
                    { icon: "", name: "Log Out", hColor: Theme.accent, cmd: "hyprctl dispatch exit" },
                    { icon: "", name: "Reboot", hColor: Theme.accent, cmd: "systemctl reboot" },
                    { icon: "", name: "Shut Down", hColor: Theme.error, cmd: "systemctl poweroff" },
                    { icon: "", name: "Restart Shell", hColor: Theme.accent, cmd: "bash -c '(sleep 0.5 && quickshell) & disown; killall quickshell'" },
                    { icon: "", name: "Hibernate", hColor: Theme.accent, cmd: "systemctl hibernate" },
                    { icon: "", name: "Screen Off", hColor: Theme.accent, cmd: "hyprctl dispatch dpms off" },
                    { icon: "", name: "Cancel", hColor: Theme.accent, cmd: "cancel" }
                ]
                
              delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    
                    // PROPER MODULAR FIX: Uses global theme variables for the button backgrounds
                    color: pMouse.pressed ? modelData.hColor : (pMouse.containsMouse ? Theme.bgHover : Theme.bgButton)
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        // PROPER MODULAR FIX: Uses Theme.textMuted for the idle icon color
                        color: pMouse.containsMouse ? modelData.hColor : (modelData.hColor === Theme.accent ? Theme.textMuted : modelData.hColor)
                        font.family: Theme.fontName
                        font.pixelSize: 18
                    }

                    ToolTip {
                        visible: pMouse.containsMouse
                        delay: 300
                        text: modelData.name
                        y: parent.height + 8

                        contentItem: Text {
                            text: modelData.name 
                            color: Theme.textMain
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        background: Rectangle {
                            color: Theme.bgDark
                            border.width: 1
                            border.color: Theme.accent
                            radius: 8
                        }
                    }

                    MouseArea {
                        id: pMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (modelData.cmd !== "cancel") {
                                Backend.run(modelData.cmd);
                            }
                            utilityScope.isExpanded = false;
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 45
        radius: 22.5
        color: Theme.bgDark
        clip: true

        Rectangle {
            width: parent.width * GlobalState.batteryLevel
            height: parent.height
            color: Theme.bgBase
            visible: GlobalState.isLaptop
            FluidBehaviour on width {}
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            Text {
                Layout.alignment: Qt.AlignLeft
                text: GlobalState.isLaptop ? "" : ""
                color: GlobalState.isLaptop ? Theme.accent : Theme.success
                font.family: Theme.fontName
                font.pixelSize: 20
            }
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                text: GlobalState.isLaptop ? (Math.round(GlobalState.batteryLevel * 100) + "% Remaining") : "Powered by AC / DC"
                color: Theme.textMain
                font.bold: true
                font.pixelSize: 14
            }
        }
    }
}
