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
            if (percent >= 99) return "battery_full";
            if (percent >= 90) return "battery_charging_90";
            if (percent >= 80) return "battery_charging_80";
            if (percent >= 60) return "battery_charging_60";
            if (percent >= 50) return "battery_charging_50";
            if (percent >= 30) return "battery_charging_30";
            if (percent >= 20) return "battery_charging_20";
            return "battery_charging_full";
        }
        if (percent >= 99) return "battery_full";
        if (percent >= 90) return "battery_6_bar";
        if (percent >= 80) return "battery_5_bar";
        if (percent >= 60) return "battery_4_bar";
        if (percent >= 50) return "battery_3_bar";
        if (percent >= 30) return "battery_2_bar";
        if (percent >= 20) return "battery_1_bar";
        return "battery_0_bar";
    }

    readonly property color iconColor: {
        if (charging) return Utils.Theme.green;
        if (percent < 20) return Utils.Theme.red;
        if (percent < 50) return Utils.Theme.yellow;
        return Utils.Theme.green;
    }

    // --- Low-battery warnings ---
    // One notification per threshold per discharge cycle; plugging in resets
    // the latches. Matters extra since hypridle auto-suspend was dropped —
    // nothing else stops a silent drain to 0.
    property bool _warned15: false
    property bool _warned5: false

    onChargingChanged: _checkThresholds()
    onPercentChanged: _checkThresholds()
    // UPower properties arrive async and unordered at shell start — percent
    // can bind while isLaptop is still false, so re-check on every piece.
    onIsLaptopChanged: _checkThresholds()
    Component.onCompleted: _checkThresholds()

    function _checkThresholds(): void {
        // Latches clear on *recovery* above the threshold, not on AC state:
        // charging includes PendingCharge, and a weak charger flapping
        // Discharging <-> PendingCharge at low battery would re-fire the
        // warning on every flap.
        if (percent > 15) _warned15 = false;
        if (percent > 5) _warned5 = false;
        // percent > 0 skips UPower's pre-init zero reading at shell start
        if (!isLaptop || charging || percent <= 0) return;
        if (percent <= 5 && !_warned5) {
            _warned5 = true;
            _warned15 = true;
            Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", "critical",
                "Battery critically low", `${percent}% remaining — plug in now.`]);
        } else if (percent <= 15 && !_warned15) {
            _warned15 = true;
            Quickshell.execDetached(["notify-send", "-a", "Battery",
                "Battery low", `${percent}% remaining.`]);
        }
    }

    // --- Power profile ---
    property string powerProfile: "balanced"

    function setProfile(profile: string) {
        setProfileProc.command = ["powerprofilesctl", "set", profile];
        setProfileProc.running = true;
    }

    // Re-read the profile — external changes (keybind, TLP) aren't pushed to
    // us, so BatteryPopout re-polls on open.
    function refreshProfile(): void {
        profileProc.running = true;
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
}
