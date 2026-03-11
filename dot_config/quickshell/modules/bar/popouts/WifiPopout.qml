pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    Component.onCompleted: { Services.Network.poll(); Services.Network.scan(); }

    // Width spacer — forces ColumnLayout's implicitWidth
    Item {
        implicitWidth: 280
        implicitHeight: 0
    }

    // --- Header: icon + SSID + disconnect button ---
    // Uses crossfade between connected (two-line) and disconnected (single centered) states
    RowLayout {
        id: headerRow

        readonly property bool isConnected: Services.Network.state === "connected"

        spacing: Utils.Theme.spacingNormal

        Text {
            text: {
                if (!headerRow.isConnected) return "󰤮";
                const icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
                return icons[Services.Network.signalLevel];
            }
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 24
            color: headerRow.isConnected ? Utils.Theme.green : Utils.Theme.overlay0
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        // Connected: two-line column (SSID + details)
        ColumnLayout {
            id: connectedHeader
            visible: headerRow.isConnected && Services.Network.ssid !== ""
            spacing: 2
            Layout.fillWidth: true
            opacity: 0

            Component.onCompleted: opacity = visible ? 1 : 0
            onVisibleChanged: opacity = visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Text {
                text: Services.Network.ssid
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
                color: Utils.Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: {
                    const parts = [];
                    if (Services.Network.ipAddress) parts.push(Services.Network.ipAddress);
                    if (Services.Network.frequency) parts.push(Services.Network.frequency);
                    return parts.join(" · ");
                }
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Disconnected: single centered label
        Text {
            id: disconnectedHeader
            visible: !headerRow.isConnected || Services.Network.ssid === ""
            text: Services.Network.disconnecting ? "Disconnecting…" : "Disconnected"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
            color: Utils.Theme.text
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            opacity: 0

            Component.onCompleted: opacity = visible ? 1 : 0
            onVisibleChanged: opacity = visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        // Disconnect button (only when connected)
        Utils.MaterialIcon {
            visible: opacity > 0
            opacity: headerRow.isConnected ? 1 : 0
            text: "link_off"
            font.pixelSize: 18
            color: disconnectMouse.containsMouse ? Utils.Theme.red : Utils.Theme.overlay1

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: disconnectMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Network.disconnect()
            }
        }
    }

    // --- Separator ---
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // --- Section header: "Networks" + scan button ---
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Text {
            text: "Networks"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Utils.Theme.subtext0
            Layout.fillWidth: true
        }

        Utils.MaterialIcon {
            id: refreshIcon
            text: "refresh"
            font.pixelSize: 18
            color: refreshMouse.containsMouse ? Utils.Theme.text : Utils.Theme.overlay1

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            RotationAnimation on rotation {
                running: Services.Network.scanning
                from: 0
                to: 360
                duration: 800
                loops: Animation.Infinite
            }

            // Reset rotation when not scanning
            Connections {
                target: Services.Network
                function onScanningChanged() {
                    if (!Services.Network.scanning) refreshIcon.rotation = 0;
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Network.scan()
            }
        }
    }

    // --- Network list ---
    Item {
        Layout.fillWidth: true
        implicitHeight: 180
        clip: true

        ListView {
            id: networkList
            anchors.fill: parent
            model: Services.Network.networks
            spacing: 2

            delegate: Rectangle {
                id: networkDelegate

                required property int index
                required property string ssid
                required property string security
                required property int signal
                required property bool connected
                required property bool known

                readonly property bool isConnecting: Services.Network.connectingTo === ssid
                readonly property bool clickable: known && !connected && !isConnecting

                width: networkList.width
                height: 32
                radius: 6
                color: "transparent"

                // Hover background
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Utils.Theme.surface1
                    opacity: networkDelegate.clickable && delegateMouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: Utils.Theme.spacingNormal

                    // Signal strength icon
                    Text {
                        text: {
                            const icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
                            return icons[Math.min(networkDelegate.signal, 4)];
                        }
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: 14
                        color: networkDelegate.connected ? Utils.Theme.green : Utils.Theme.overlay1
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // SSID
                    Text {
                        text: networkDelegate.ssid
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: 13
                        color: Utils.Theme.text
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
                        color: Utils.Theme.overlay1
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Connected check
                    Utils.MaterialIcon {
                        visible: networkDelegate.connected && !networkDelegate.isConnecting
                        text: "check"
                        font.pixelSize: 16
                        color: Utils.Theme.green
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Dim unknown networks
                opacity: networkDelegate.known || networkDelegate.connected ? 1.0 : 0.6

                MouseArea {
                    id: delegateMouse
                    anchors.fill: parent
                    hoverEnabled: networkDelegate.clickable
                    cursorShape: networkDelegate.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: networkDelegate.clickable
                    onClicked: Services.Network.connect(networkDelegate.ssid)
                }
            }
        }

        // Empty state
        Text {
            visible: Services.Network.networks.count === 0
            anchors.centerIn: parent
            text: Services.Network.scanning ? "Scanning..." : "No networks found"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            font.italic: true
            color: Utils.Theme.overlay0
        }
    }

    // --- Separator ---
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // --- Open Impala pill button ---
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        radius: Utils.Theme.roundingFull
        color: Utils.Theme.surface0
        border.width: 1
        border.color: impalaMouse.containsMouse ? Utils.Theme.surface2 : Utils.Theme.surface1

        Behavior on border.color {
            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Utils.Theme.surface1
            opacity: impalaMouse.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Utils.MaterialIcon {
                text: "terminal"
                font.pixelSize: 14
                color: Utils.Theme.subtext1
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Open Impala"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Utils.Theme.subtext1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: impalaMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: impalaProc.running = true
        }
    }

    Process {
        id: impalaProc
        command: ["sh", "-c", "setsid ghostty -e impala &"]
    }
}
