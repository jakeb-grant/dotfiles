pragma Singleton

import Quickshell
import Quickshell.Bluetooth as BT
import QtQuick

Singleton {
    id: root

    readonly property BT.BluetoothAdapter adapter: BT.Bluetooth.defaultAdapter

    readonly property bool powered: adapter?.enabled ?? false

    // Our own scan state — not bound to adapter.discovering which may be externally managed
    property bool scanning: false

    // First connected device (for header/icon)
    readonly property BT.BluetoothDevice connectedDevice: {
        if (!adapter) return null;
        const devs = adapter.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i];
        }
        return null;
    }

    // Stable ListModel mirroring adapter.devices (avoids DelegateModel index warnings)
    property ListModel devices: ListModel {}

    // Native device refs for connect/disconnect by address
    property var _deviceRefs: ({})

    function _syncDevices() {
        if (!adapter) return;

        const devs = adapter.devices.values;
        const entries = [];
        const refs = {};

        for (let i = 0; i < devs.length; i++) {
            const dev = devs[i];
            if (!dev) continue;
            const addr = dev.address;
            refs[addr] = dev;
            entries.push({
                address: addr,
                name: dev.name || dev.deviceName || addr,
                paired: dev.paired,
                connected: dev.connected,
                icon: dev.icon || "",
                batteryAvailable: dev.batteryAvailable ?? false,
                battery: dev.battery ?? 0,
                pairing: dev.pairing ?? false,
                connecting: dev.state === BT.BluetoothDeviceState.Connecting,
                disconnecting: dev.state === BT.BluetoothDeviceState.Disconnecting
            });
        }

        // Sort: connected first, then paired, then alphabetical
        entries.sort((a, b) => {
            if (a.connected !== b.connected) return b.connected - a.connected;
            if (a.paired !== b.paired) return b.paired - a.paired;
            return a.name.localeCompare(b.name);
        });

        // In-place update to avoid delegate index warnings
        for (let i = 0; i < entries.length; i++) {
            if (i < devices.count) {
                devices.set(i, entries[i]);
            } else {
                devices.append(entries[i]);
            }
        }
        while (devices.count > entries.length) {
            devices.remove(devices.count - 1);
        }

        _deviceRefs = refs;
    }

    // Re-sync when adapter device list changes
    Connections {
        target: root.adapter?.devices ?? null

        function onObjectInsertedPost() { root._syncDevices(); }
        function onObjectRemovedPost() { root._syncDevices(); }
    }

    // Also re-sync periodically to catch property changes (connected, battery, etc.)
    Timer {
        id: syncTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: root._syncDevices()
    }

    property bool _weStartedDiscovery: false

    function scan() {
        if (!adapter || !adapter.enabled) return;
        scanning = true;

        if (!adapter.discovering) {
            adapter.discovering = true;
            _weStartedDiscovery = true;
        }

        scanTimer.restart();
    }

    Timer {
        id: scanTimer
        interval: 5000
        onTriggered: {
            root.scanning = false;
            // Only stop discovery if we started it
            if (root._weStartedDiscovery && root.adapter) {
                root.adapter.discovering = false;
                root._weStartedDiscovery = false;
            }
            root._syncDevices();
        }
    }

    function connectDevice(address) {
        const dev = _deviceRefs[address];
        if (!dev || dev.connected) return;

        if (dev.paired) {
            dev.connect();
        } else {
            // Pair first, then connect once paired
            _pendingConnect = address;
            dev.pair();
        }
    }

    property string _pendingConnect: ""

    Connections {
        target: root._deviceRefs[root._pendingConnect] ?? null

        function onPairedChanged() {
            const dev = root._deviceRefs[root._pendingConnect];
            if (dev && dev.paired) {
                root._pendingConnect = "";
                dev.connect();
            }
        }
    }

    function disconnectDevice(address) {
        const dev = _deviceRefs[address];
        if (dev) dev.disconnect();
    }

    function togglePower() {
        if (adapter) adapter.enabled = !adapter.enabled;
    }
}
