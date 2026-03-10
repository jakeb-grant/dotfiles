pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string ssid: ""
    property string state: "disconnected"
    readonly property string label: ssid || "offline"

    Process {
        id: proc
        command: ["iwctl", "station", "wlan0", "show"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.includes("Connected network")) {
                    root.ssid = line.split(/\s{2,}/).pop().trim();
                } else if (line.includes("State")) {
                    if (line.includes("connected")) {
                        root.state = "connected";
                    } else {
                        root.state = "disconnected";
                        root.ssid = "";
                    }
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: proc.running = true
    }
}
