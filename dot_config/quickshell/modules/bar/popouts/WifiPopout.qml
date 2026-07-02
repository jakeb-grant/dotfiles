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

    Component.onCompleted: { Services.Network.poll(); Services.Network.scan(); }

    ConnectionHeader {
        connected: Services.Network.state === "connected"
        title: Services.Network.ssid
        subtitle: {
            const parts = [];
            if (Services.Network.ipAddress) parts.push(Services.Network.ipAddress);
            if (Services.Network.frequency) parts.push(Services.Network.frequency);
            return parts.join(" · ");
        }
        disconnectedText: Services.Network.disconnecting ? "Disconnecting…" : "Disconnected"
        onDisconnectClicked: Services.Network.disconnect()

        icon: Text {
            text: Services.Network.signalIcon
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.headerIconSize
            color: Services.Network.state === "connected" ? Utils.Theme.accent : Utils.Theme.subtleText

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }
    }

    Separator {}

    SectionHeader {
        title: "Networks"
        showRefresh: true
        spinning: Services.Network.scanning
        onRefreshClicked: Services.Network.scan()
    }

    PopoutListView {
        Layout.fillWidth: true
        model: Services.Network.networks
        emptyText: Services.Network.scanning ? "Scanning..." : "No networks found"

        delegate: ListRow {
            id: networkDelegate

            required property int index
            required property string ssid
            required property string security
            required property int signal
            required property bool connected
            required property bool known

            readonly property bool isConnecting: Services.Network.connectingTo === ssid
            readonly property bool clickable: known && !connected && !isConnecting

            width: ListView.view.width
            interactive: clickable
            onClicked: Services.Network.connect(ssid)

            // Signal strength icon
            Text {
                text: Services.Network.signalIconFor(networkDelegate.signal)
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.iconSizeSmall
                color: networkDelegate.connected ? Utils.Theme.accent : Utils.Theme.subtleText
                Layout.alignment: Qt.AlignVCenter
            }

            // SSID
            Text {
                text: networkDelegate.ssid
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.listFontSize
                color: networkDelegate.known || networkDelegate.connected ? Utils.Theme.text : Utils.Theme.subtleText
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Connecting indicator
            Text {
                visible: networkDelegate.isConnecting
                text: "Connecting..."
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                font.italic: true
                color: Utils.Theme.subtext0
                Layout.alignment: Qt.AlignVCenter
            }

            // Connected check
            Utils.MaterialIcon {
                visible: networkDelegate.connected && !networkDelegate.isConnecting
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
        label: "Open Impala"
        onClicked: impalaProc.running = true
    }

    Process {
        id: impalaProc
        command: ["sh", "-c", "setsid ghostty -e impala &"]
    }
}
