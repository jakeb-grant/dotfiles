pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property date date: clock.date
    readonly property string hours: {
        const h = clock.date.getHours() % 12;
        const h12 = h === 0 ? 12 : h;
        return h12.toString().padStart(2, '0');
    }
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")
    readonly property string ampm: clock.date.getHours() >= 12 ? "pm" : "am"

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
