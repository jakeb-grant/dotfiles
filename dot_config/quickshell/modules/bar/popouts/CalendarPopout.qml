import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: 280
        implicitHeight: 0
    }

    readonly property int cellSize: 32
    readonly property int gridSpacing: 2

    // View state — month/year being displayed
    property int viewMonth: today.getMonth()
    property int viewYear: today.getFullYear()
    readonly property date today: Services.Clock.date

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

        Utils.MaterialIcon {
            text: "chevron_left"
            font.pixelSize: 18
            color: navLeftMouse.containsMouse ? Utils.Theme.text : Utils.Theme.overlay1

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: navLeftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.prevMonth()
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: Qt.formatDate(root.firstOfMonth, "MMMM yyyy")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 13
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

        Utils.MaterialIcon {
            text: "chevron_right"
            font.pixelSize: 18
            color: navRightMouse.containsMouse ? Utils.Theme.text : Utils.Theme.overlay1

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: navRightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextMonth()
            }
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
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Utils.Theme.overlay0
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
                        ? Utils.Theme.blue
                        : dayCellMouse.containsMouse && dayCell.inMonth
                            ? Utils.Theme.surface1
                            : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.inMonth ? dayCell.dayNum : ""
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                        color: dayCell.isToday
                            ? Utils.Theme.crust
                            : Utils.Theme.subtext0
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

    // Separator
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface0
        opacity: 0.6
    }

    // Current time
    RowLayout {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingSmall

        Text {
            text: Services.Clock.format("dddd")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 11
            color: Utils.Theme.overlay1
        }

        Item { Layout.fillWidth: true }

        Text {
            text: Services.Clock.format("h:mm AP")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Utils.Theme.teal
        }
    }
}
