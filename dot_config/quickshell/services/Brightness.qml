pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool available: false
    property int percent: 0
    readonly property real brightness: percent / 100
    property bool suppressUpdates: false

    property int _max: 0
    property string _sysfsPath: ""

    Timer {
        id: resyncDelay
        interval: 800
        onTriggered: root.suppressUpdates = false
    }

    function beginUserInput(): void {
        suppressUpdates = true;
        resyncDelay.stop();
    }

    function endUserInput(): void {
        resyncDelay.restart();
    }

    // Step 1: Detect backlight device + get sysfs path and max
    // brightnessctl info -m outputs: device,class,current,percent,max
    Process {
        id: infoProc
        command: ["brightnessctl", "info", "-m"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",");
                if (parts.length >= 5) {
                    const device = parts[0];
                    const maxVal = parseInt(parts[4]);
                    if (maxVal > 0 && device) {
                        root._max = maxVal;
                        root._sysfsPath = "/sys/class/backlight/" + device + "/brightness";
                        root.available = true;
                    }
                }
            }
        }
    }

    // Step 2: Watch sysfs brightness file for changes (keybinds, brightnessctl, etc.)
    FileView {
        id: brightnessFile
        path: root._sysfsPath
        watchChanges: true
        onFileChanged: reload()
    }

    // Derive percent from file contents whenever it changes
    onAvailableChanged: {
        if (available) brightnessFile.reload();
    }

    readonly property int _currentRaw: {
        if (!available || !brightnessFile.loaded) return 0;
        return parseInt(brightnessFile.text()) || 0;
    }

    on_CurrentRawChanged: {
        if (_max > 0 && !suppressUpdates)
            percent = Math.round(_currentRaw / _max * 100);
    }

    // Set brightness
    Process {
        id: setProc
    }

    function setBrightness(pct: int): void {
        const clamped = Math.round(Math.max(1, Math.min(100, pct)));
        setProc.command = ["brightnessctl", "set", clamped + "%"];
        setProc.running = true;
    }

    function increment(): void { setBrightness(percent + 5); }
    function decrement(): void { setBrightness(percent - 5); }
}
