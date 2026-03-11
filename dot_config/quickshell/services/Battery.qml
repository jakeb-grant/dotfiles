pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.utils as Utils

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

    readonly property string icon: {
        if (charging) {
            if (percent >= 90) return "battery_charging_full";
            if (percent >= 80) return "battery_charging_6_bar";
            if (percent >= 60) return "battery_charging_5_bar";
            if (percent >= 40) return "battery_charging_4_bar";
            if (percent >= 25) return "battery_charging_3_bar";
            if (percent >= 10) return "battery_charging_2_bar";
            return "battery_charging_1_bar";
        }
        if (percent >= 90) return "battery_full";
        if (percent >= 80) return "battery_6_bar";
        if (percent >= 60) return "battery_5_bar";
        if (percent >= 40) return "battery_4_bar";
        if (percent >= 25) return "battery_3_bar";
        if (percent >= 10) return "battery_2_bar";
        return "battery_1_bar";
    }

    readonly property color iconColor: {
        if (charging) return Utils.Theme.green;
        if (percent < 10) return Utils.Theme.red;
        if (percent < 25) return Utils.Theme.peach;
        if (percent < 50) return Utils.Theme.yellow;
        if (percent < 75) return Utils.Theme.teal;
        return Utils.Theme.green;
    }

    // --- Power profile ---
    property string powerProfile: "balanced"

    function setProfile(profile: string) {
        setProfileProc.command = ["powerprofilesctl", "set", profile];
        setProfileProc.running = true;
    }

    Process {
        id: profileProc
        command: ["powerprofilesctl", "get"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const p = data.trim();
                if (p !== "") root.powerProfile = p;
            }
        }
    }

    Process {
        id: setProfileProc

        onRunningChanged: {
            if (!running) profileProc.running = true;
        }
    }

    Component.onCompleted: profileProc.running = true
}
