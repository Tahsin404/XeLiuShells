// ~/.config/quickshell/widgets/topbar/ExpandedCalendar.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../core"

Item {
    id: root
    anchors.fill: parent
    property bool isExpanded: false
    opacity: isExpanded ? 1 : 0

    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()
    property bool isNavigating: false

    function triggerScroll(isMonth, direction) {
        if (isNavigating)
            return;
        var realYear = new Date().getFullYear();
        var minYear = realYear - 10;
        var maxYear = realYear + 10;

        if (isMonth) {
            var tMonth = displayMonth + direction;
            var tYear = displayYear;
            if (tMonth > 11) {
                tMonth = 0;
                tYear += 1;
            } else if (tMonth < 0) {
                tMonth = 11;
                tYear -= 1;
            }
            if (tYear < minYear || tYear > maxYear)
                return;

            isNavigating = true;
            monthAnim.direction = direction;
            monthAnim.nextMonth = tMonth;
            monthAnim.nextYear = tYear;
            monthAnim.start();
        } else {
            var tYear2 = displayYear + direction;
            if (tYear2 < minYear || tYear2 > maxYear)
                return;
            isNavigating = true;
            yearAnim.direction = direction;
            yearAnim.nextYear = tYear2;
            yearAnim.start();
        }
    }

    SequentialAnimation {
        id: monthAnim
        property int direction: 1
        property int nextMonth: 0
        property int nextYear: 0
        ParallelAnimation {
            NumberAnimation {
                target: monthGrid
                property: "opacity"
                to: 0
                duration: 150
            }
            NumberAnimation {
                target: monthText
                property: "opacity"
                to: 0
                duration: 150
            }
            NumberAnimation {
                target: monthTranslate
                property: "y"
                to: monthAnim.direction * -15
                duration: 150
            }
        }
        ScriptAction {
            script: {
                root.displayMonth = monthAnim.nextMonth;
                root.displayYear = monthAnim.nextYear;
                monthTranslate.y = monthAnim.direction * 15;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: monthGrid
                property: "opacity"
                to: 1
                duration: 150
            }
            NumberAnimation {
                target: monthText
                property: "opacity"
                to: 1
                duration: 150
            }
            NumberAnimation {
                target: monthTranslate
                property: "y"
                to: 0
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                root.isNavigating = false;
            }
        }
    }

    SequentialAnimation {
        id: yearAnim
        property int direction: 1
        property int nextYear: 0
        ParallelAnimation {
            NumberAnimation {
                target: monthGrid
                property: "opacity"
                to: 0
                duration: 150
            }
            NumberAnimation {
                target: yearText
                property: "opacity"
                to: 0
                duration: 150
            }
            NumberAnimation {
                target: yearTranslate
                property: "y"
                to: yearAnim.direction * -15
                duration: 150
            }
        }
        ScriptAction {
            script: {
                root.displayYear = yearAnim.nextYear;
                yearTranslate.y = yearAnim.direction * 15;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: monthGrid
                property: "opacity"
                to: 1
                duration: 150
            }
            NumberAnimation {
                target: yearText
                property: "opacity"
                to: 1
                duration: 150
            }
            NumberAnimation {
                target: yearTranslate
                property: "y"
                to: 0
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                root.isNavigating = false;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 30
            Layout.topMargin: 15
            text: GlobalState.upperDayString
            color: Theme.textMain
            font.family: Theme.fontName
            font.pixelSize: 50
            font.bold: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            Layout.rightMargin: 40
            spacing: 8
            Item {
                Layout.fillWidth: true
            }

            Text {
                id: monthText
                text: Qt.formatDate(new Date(root.displayYear, root.displayMonth, 1), "MMMM").toUpperCase()
                color: Theme.textMain
                font.family: Theme.fontName
                font.pixelSize: 18
                font.bold: true
                transform: Translate {
                    id: monthTranslate
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    onWheel: wheel => {
                        root.triggerScroll(true, wheel.angleDelta.y < 0 ? 1 : -1);
                    }
                }
            }
            Text {
                id: yearText
                text: root.displayYear.toString()
                color: Theme.textMain
                font.family: Theme.fontName
                font.pixelSize: 18
                font.bold: true
                transform: Translate {
                    id: yearTranslate
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    onWheel: wheel => {
                        root.triggerScroll(false, wheel.angleDelta.y < 0 ? 1 : -1);
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.15)
            radius: 15
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: monthGrid.locale
                    delegate: Text {
                        required property var model
                        text: model.shortName
                        color: Theme.textMuted
                        font.family: Theme.fontName
                        font.pixelSize: 22
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                MonthGrid {
                    id: monthGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    month: root.displayMonth
                    year: root.displayYear
                    locale: Qt.locale()
                    delegate: Rectangle {
                        required property var model
                        color: dayMouseArea.containsMouse ? (model.today ? "transparent" : Theme.bgHover) : "transparent"
                        radius: 15
                        MouseArea {
                            id: dayMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            enabled: root.isExpanded
                            propagateComposedEvents: true
                            onClicked: function (mouse) {
                                mouse.accepted = false;
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 60
                            height: 60
                            radius: 25
                            border.width: 2
                            border.color: model.today ? Theme.textMain : "transparent"
                            color: "transparent"
                        }
                        Text {
                            id: dayText
                            anchors.centerIn: parent
                            text: model.day
                            font.family: Theme.fontName
                            font.pixelSize: 24
                            font.weight: model.month === monthGrid.month ? Font.DemiBold : Font.Light
                            opacity: model.month === monthGrid.month ? 1.0 : 0.3
                            color: Theme.textMain
                        }
                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: Theme.accent
                            anchors.top: dayText.bottom
                            anchors.topMargin: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: {
                                var loadedDates = GlobalState.eventDates;
                                return loadedDates.indexOf(Qt.formatDate(model.date, "yyyy-MM-dd")) !== -1 && model.month === monthGrid.month;
                            }
                        }
                    }
                }
            }
        }
    }
    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation {
                duration: root.isExpanded ? 150 : 0
            }
            NumberAnimation {
                duration: 250
            }
        }
    }
}
