pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    Component.onCompleted: Services.Bluetooth._syncDevices()

    ConnectionHeader {
        connected: Services.Bluetooth.connectedDevice !== null
        title: Services.Bluetooth.connectedDevice?.name ?? ""
        subtitle: {
            const dev = Services.Bluetooth.connectedDevice;
            if (!dev) return "";
            const parts = ["Connected"];
            if (dev.batteryAvailable)
                parts.push(Math.round(dev.battery * 100) + "%");
            return parts.join(" · ");
        }
        disconnectedText: Services.Bluetooth.powered ? "No device" : "Bluetooth off"
        onDisconnectClicked: {
            const dev = Services.Bluetooth.connectedDevice;
            if (dev) Services.Bluetooth.disconnectDevice(dev.address);
        }

        icon: Utils.MaterialIcon {
            text: Services.Bluetooth.connectedDevice !== null ? "bluetooth_connected" : "bluetooth"
            font.pixelSize: Utils.Theme.headerIconSize
            color: Services.Bluetooth.connectedDevice !== null ? Utils.Theme.accent : Utils.Theme.subtleText

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }
    }

    Separator {}

    SectionHeader {
        title: "Devices"
        showRefresh: Services.Bluetooth.powered
        spinning: Services.Bluetooth.scanning
        onRefreshClicked: Services.Bluetooth.scan()

        // Power toggle
        IconButton {
            text: Services.Bluetooth.powered ? "toggle_on" : "toggle_off"
            font.pixelSize: Utils.Theme.headerActionIconSize
            baseColor: Services.Bluetooth.powered ? Utils.Theme.accent : Utils.Theme.subtleText
            hoverColor: Services.Bluetooth.powered ? Utils.Theme.red : Utils.Theme.accent
            onClicked: Services.Bluetooth.togglePower()
        }
    }

    PopoutListView {
        Layout.fillWidth: true
        model: Services.Bluetooth.devices
        emptyText: {
            if (!Services.Bluetooth.powered) return "Bluetooth is off";
            if (Services.Bluetooth.scanning) return "Scanning...";
            return "No devices found";
        }

        delegate: ListRow {
            id: deviceDelegate

            required property int index
            required property string address
            required property string name
            required property bool paired
            required property bool connected
            required property string icon
            required property bool batteryAvailable
            required property real battery
            required property bool pairing
            required property bool connecting
            required property bool disconnecting

            readonly property bool clickable: !connected && !connecting && !pairing

            width: ListView.view.width
            interactive: clickable
            onClicked: Services.Bluetooth.connectDevice(address)

            // Device type icon
            Utils.MaterialIcon {
                text: {
                    const ic = deviceDelegate.icon;
                    if (ic.includes("audio")) return "headphones";
                    if (ic.includes("phone")) return "smartphone";
                    if (ic.includes("computer")) return "computer";
                    if (ic.includes("input") || ic.includes("keyboard")) return "keyboard";
                    if (ic.includes("video") || ic.includes("tv")) return "tv";
                    if (ic.includes("mouse")) return "mouse";
                    return "bluetooth";
                }
                font.pixelSize: Utils.Theme.iconSizeSmall
                color: deviceDelegate.connected ? Utils.Theme.accent : Utils.Theme.subtleText
                Layout.alignment: Qt.AlignVCenter
            }

            // Device name
            Text {
                text: deviceDelegate.name
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.listFontSize
                color: Utils.Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Battery indicator
            Text {
                visible: deviceDelegate.connected && deviceDelegate.batteryAvailable
                text: Math.round(deviceDelegate.battery * 100) + "%"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
                Layout.alignment: Qt.AlignVCenter
            }

            // Status indicator
            Text {
                visible: deviceDelegate.connecting || deviceDelegate.disconnecting || deviceDelegate.pairing
                text: deviceDelegate.pairing ? "Pairing..." : deviceDelegate.connecting ? "Connecting..." : "Disconnecting..."
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                font.italic: true
                color: Utils.Theme.subtext0
                Layout.alignment: Qt.AlignVCenter
            }

            // Connected check
            Utils.MaterialIcon {
                visible: deviceDelegate.connected && !deviceDelegate.disconnecting
                text: "check"
                font.pixelSize: Utils.Theme.headerFontSize
                color: Utils.Theme.accent
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Separator {}

    PillButton {
        Layout.fillWidth: true
        icon: "terminal"
        label: "Open bluetui"
        onClicked: bluetuiProc.running = true
    }

    Process {
        id: bluetuiProc
        command: ["sh", "-c", "setsid ghostty -e bluetui &"]
    }
}
