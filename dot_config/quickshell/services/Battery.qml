pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property real percentage: UPower.displayDevice.percentage
    readonly property int percent: Math.round(percentage * 100)
    readonly property bool charging: {
        const s = UPower.displayDevice.state;
        return s === UPowerDeviceState.Charging
            || s === UPowerDeviceState.FullyCharged
            || s === UPowerDeviceState.PendingCharge;
    }
    readonly property bool isLaptop: UPower.displayDevice.isLaptopBattery
    readonly property string label: percent + "%"
}
