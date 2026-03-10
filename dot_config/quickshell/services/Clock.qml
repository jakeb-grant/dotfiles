pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property date date: clock.date
    readonly property string hours: Qt.formatDateTime(clock.date, "hh")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
