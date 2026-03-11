pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string ssid: ""
    property string state: "disconnected"
    readonly property string label: ssid || "offline"

    // Detail properties from iwctl station show
    property string ipAddress: ""
    property string security: ""
    property string frequency: ""
    property int signalDbm: 0

    // Signal level 0-4 derived from RSSI dBm
    readonly property int signalLevel: {
        if (state !== "connected" || signalDbm === 0) return 0;
        const dbm = signalDbm;
        if (dbm >= -50) return 4;
        if (dbm >= -60) return 3;
        if (dbm >= -70) return 2;
        if (dbm >= -80) return 1;
        return 0;
    }

    // Scanning/connecting state
    property bool scanning: false
    property string connectingTo: ""

    // Network list model: ssid, security, signal (0-4), connected, known
    property ListModel networks: ListModel {}

    // Known network SSIDs
    property var knownNetworks: ({})

    // --- Status polling (single-line output to avoid race conditions) ---
    Process {
        id: proc
        // Outputs one line: state|ssid|ip|security|freq_mhz|rssi_dbm
        command: ["sh", "-c", "iwctl station wlan0 show | sed 's/\\x1b\\[[0-9;]*m//g' | awk '/State/{st=$NF} /Connected network/{ssid=$NF} /IPv4 address/{ip=$NF} /Security/{sec=$NF} /Frequency/{freq=$NF} /^ *RSSI/{rssi=$(NF-1)} END{print st\"|\"ssid\"|\"ip\"|\"sec\"|\"freq\"|\"rssi}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (root.disconnecting || root.connectingTo !== "") return;

                const parts = data.split("|");
                if (parts.length < 6) return;

                const st = parts[0].trim();
                const ssid = parts[1].trim();
                const ip = parts[2].trim();
                const sec = parts[3].trim();
                const freqRaw = parts[4].trim();
                const rssi = parseInt(parts[5].trim()) || 0;

                if (st.includes("disconnected")) {
                    root.state = "disconnected";
                    root.ssid = "";
                    root.ipAddress = "";
                    root.security = "";
                    root.frequency = "";
                    root.signalDbm = 0;
                } else if (st.includes("connected")) {
                    root.state = "connected";
                    root.ssid = ssid;
                    root.ipAddress = ip;
                    root.security = sec;
                    root.signalDbm = rssi;

                    const mhz = parseInt(freqRaw);
                    if (mhz > 4900) root.frequency = "5 GHz";
                    else if (mhz > 2000) root.frequency = "2.4 GHz";
                    else root.frequency = freqRaw;
                }
            }
        }
    }

    // Track previous state to detect external changes
    property string _prevState: ""

    onStateChanged: {
        if (_prevState !== "" && state !== _prevState) {
            // State changed externally — rescan network list
            scan();
        }
        _prevState = state;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    // --- Poll status immediately ---
    function poll() {
        proc.running = true;
    }

    // --- Scan ---
    function scan() {
        root.scanning = true;
        scanProc.running = true;
    }

    Process {
        id: scanProc
        command: ["iwctl", "station", "wlan0", "scan"]

        onRunningChanged: {
            if (!running) {
                // Scan submitted, now fetch known networks + network list
                knownProc.running = true;
                listProc.running = true;
            }
        }
    }

    // --- Known networks ---
    Process {
        id: knownProc
        command: ["sh", "-c", "iwctl known-networks list | sed 's/\\x1b\\[[0-9;]*m//g'"]

        property var _names: ({})

        stdout: SplitParser {
            onRead: data => {
                const line = data;
                // Skip header/separator lines
                if (line.includes("Known Networks") || line.includes("---") || line.trim() === "") return;
                // Format: "  SSID                  Security  ..."
                // SSID is the first column, typically left-aligned with leading spaces
                const parts = line.trim().split(/\s{2,}/);
                if (parts.length >= 1 && parts[0] !== "Name") {
                    knownProc._names[parts[0]] = true;
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                root.knownNetworks = knownProc._names;
                knownProc._names = {};
            }
        }
    }

    // --- Network list ---
    Process {
        id: listProc
        command: ["sh", "-c", "iwctl station wlan0 get-networks rssi-dbms | sed 's/\\x1b\\[[0-9;]*m//g'"]

        property var _entries: []

        function dbmToLevel(raw: int): int {
            // iwctl rssi-dbms gives centidBm (e.g. -5900 = -59 dBm)
            const dbm = raw / 100;
            if (dbm >= -50) return 4;
            if (dbm >= -60) return 3;
            if (dbm >= -70) return 2;
            if (dbm >= -80) return 1;
            return 0;
        }

        stdout: SplitParser {
            onRead: data => {
                const line = data;
                // Skip header lines
                if (line.includes("Available") || line.includes("---") || line.trim() === "") return;

                // Detect connected marker
                const connected = line.replace(/^\s+/, "").startsWith(">");
                // Strip the > prefix if present
                const cleaned = connected ? line.replace(/^\s*>\s*/, "  ") : line;

                const trimmed = cleaned.trim();
                if (trimmed === "" || trimmed === "Name" || trimmed.startsWith("Network")) return;

                // Split by 2+ spaces
                const parts = trimmed.split(/\s{2,}/);
                if (parts.length < 2) return;

                // Last token is rssi in centidBm (e.g. -5900)
                const rssiRaw = parseInt(parts[parts.length - 1]) || 0;
                const signal = listProc.dbmToLevel(rssiRaw);

                // Security is second-to-last
                const sec = parts.length >= 3 ? parts[parts.length - 2] : "";

                // SSID is everything before security
                const ssidParts = parts.slice(0, parts.length >= 3 ? parts.length - 2 : parts.length - 1);
                const ssid = ssidParts.join("  ").trim();

                if (ssid === "" || ssid === "Name") return;

                listProc._entries.push({
                    ssid: ssid,
                    security: sec,
                    signal: signal,
                    connected: connected,
                    known: false // will be set after
                });
            }
        }

        onRunningChanged: {
            if (!running) {
                // Update model in-place to avoid delegate index warnings
                const entries = listProc._entries;
                for (let i = 0; i < entries.length; i++) {
                    entries[i].known = (entries[i].ssid in root.knownNetworks);
                    if (i < root.networks.count) {
                        root.networks.set(i, entries[i]);
                    } else {
                        root.networks.append(entries[i]);
                    }
                }
                // Remove excess old entries from the end
                while (root.networks.count > entries.length) {
                    root.networks.remove(root.networks.count - 1);
                }
                listProc._entries = [];
                root.scanning = false;
            }
        }
    }

    // --- Connect ---
    function connect(ssid) {
        root.connectingTo = ssid;
        connectProc.command = ["iwctl", "station", "wlan0", "connect", ssid];
        connectProc.running = true;
    }

    Process {
        id: connectProc

        onRunningChanged: {
            if (!running) {
                root.connectingTo = "";
                // Re-poll status
                proc.running = true;
                // Refresh network list after a short delay
                connectRefreshTimer.restart();
            }
        }
    }

    Timer {
        id: connectRefreshTimer
        interval: 1500
        onTriggered: root.scan()
    }

    // --- Disconnect ---
    property bool disconnecting: false

    function disconnect() {
        root.disconnecting = true;
        root.state = "disconnected";
        root.ssid = "";
        root.ipAddress = "";
        root.security = "";
        root.frequency = "";
        root.signalDbm = 0;
        disconnectProc.running = true;
    }

    Process {
        id: disconnectProc
        command: ["iwctl", "station", "wlan0", "disconnect"]

        onRunningChanged: {
            if (!running) {
                root.disconnecting = false;
                proc.running = true;
                disconnectRefreshTimer.restart();
            }
        }
    }

    Timer {
        id: disconnectRefreshTimer
        interval: 1500
        onTriggered: root.scan()
    }
}
