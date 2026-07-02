import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    readonly property int cellSize: 32
    readonly property int gridSpacing: 2

    // View state — month/year being displayed. Initialized once; not bound to
    // `today` so midnight rollover doesn't snap the view back when the user
    // has navigated to a different month.
    property int viewMonth: 0
    property int viewYear: 1970
    readonly property date today: Services.Clock.date

    Component.onCompleted: {
        viewMonth = today.getMonth();
        viewYear = today.getFullYear();
    }

    // First day of the viewed month
    readonly property date firstOfMonth: new Date(viewYear, viewMonth, 1)
    // Days in the viewed month
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()
    // Day of week the month starts on (0=Sun → offset so Mon=0)
    readonly property int startOffset: (firstOfMonth.getDay() + 6) % 7
    // Always 42 cells (6 rows) for consistent sizing
    readonly property int totalCells: 42

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
    }

    function goToday() {
        viewMonth = today.getMonth();
        viewYear = today.getFullYear();
    }

    // Month/year header with navigation
    RowLayout {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingSmall

        IconButton {
            text: "chevron_left"
            font.pixelSize: Utils.Theme.headerActionIconSize
            onClicked: root.prevMonth()
        }

        Item { Layout.fillWidth: true }

        Text {
            text: Qt.formatDate(root.firstOfMonth, "MMMM yyyy")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.listFontSize
            font.weight: Font.DemiBold
            color: Utils.Theme.text

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goToday()
            }
        }

        Item { Layout.fillWidth: true }

        IconButton {
            text: "chevron_right"
            font.pixelSize: Utils.Theme.headerActionIconSize
            onClicked: root.nextMonth()
        }
    }

    // Day-of-week headers
    Grid {
        Layout.fillWidth: true
        columns: 7
        spacing: root.gridSpacing

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Text {
                required property string modelData
                width: root.cellSize
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.calendarHeaderFontSize
                font.weight: Font.Medium
                color: Utils.Theme.disabledText
            }
        }
    }

    // Day grid
    Grid {
        Layout.fillWidth: true
        columns: 7
        spacing: root.gridSpacing

        Repeater {
            model: root.totalCells

            Item {
                id: dayCell

                required property int index
                readonly property int dayNum: index - root.startOffset + 1
                readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth
                readonly property bool isToday: inMonth
                    && dayNum === root.today.getDate()
                    && root.viewMonth === root.today.getMonth()
                    && root.viewYear === root.today.getFullYear()

                width: root.cellSize
                height: root.cellSize

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellSize - 2
                    height: root.cellSize - 2
                    radius: root.cellSize / 2
                    color: dayCell.isToday
                        ? Utils.Theme.accent
                        : dayCellMouse.containsMouse && dayCell.inMonth
                            ? Utils.Theme.hoverBg
                            : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.inMonth ? dayCell.dayNum : ""
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.calendarDayFontSize
                        font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                        color: dayCell.isToday
                            ? Utils.Theme.crust
                            : Utils.Theme.subtext1
                    }
                }

                MouseArea {
                    id: dayCellMouse
                    anchors.fill: parent
                    hoverEnabled: dayCell.inMonth
                    cursorShape: dayCell.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    Separator {}

    // Current time
    RowLayout {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingSmall

        Text {
            text: Services.Clock.format("dddd")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtleText
        }

        Item { Layout.fillWidth: true }

        Text {
            text: Services.Clock.format("h:mm AP")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Utils.Theme.subtext1
        }
    }
}
