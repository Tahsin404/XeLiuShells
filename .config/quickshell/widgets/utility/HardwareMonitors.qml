// ~/.config/quickshell/widgets/utility/HardwareMonitors.qml
import QtQuick
import "../../core"
import "../../components"

Item {
    id: root
    width: parent.width
    height: 190

    Row {
        anchors.fill: parent
        spacing: (parent.width - (80 * 3)) / 2

        Repeater {
            model: [
                {
                    label: "CPU",
                    icon: "",
                    level: GlobalState.cpuLevel,
                    color: Theme.accent
                },
                {
                    label: "RAM",
                    icon: "",
                    level: GlobalState.ramLevel,
                    color: Theme.hardwareRam
                },
                {
                    label: "GPU",
                    icon: "",
                    level: GlobalState.gpuLevel,
                    color: Theme.hardwareGpu
                }
            ]
            delegate: HardwareMetric {
                label: modelData.label
                icon: modelData.icon
                level: modelData.level
                accentColor: modelData.color
            }
        }
    }
}
