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

    Component.onCompleted: Services.Bluetooth._syncDevices()

    // Width spacer
    Item {
        implicitWidth: Utils.Theme.popoutWidth
        implicitHeight: 0
    }

    // --- Header: icon + device name + disconnect button ---
    RowLayout {
        id: headerRow

        readonly property bool isConnected: Services.Bluetooth.connectedDevice !== null

        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: headerRow.isConnected ? "bluetooth_connected" : "bluetooth"
            font.pixelSize: Utils.Theme.headerIconSize
            color: headerRow.isConnected ? Utils.Theme.accent : Utils.Theme.subtleText

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        // Connected: device name + status
        ColumnLayout {
            id: connectedHeader
            visible: headerRow.isConnected
            spacing: Utils.Theme.spacingTiny
            Layout.fillWidth: true
            opacity: 0

            Component.onCompleted: opacity = visible ? 1 : 0
            onVisibleChanged: opacity = visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Text {
                text: Services.Bluetooth.connectedDevice?.name ?? ""
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.headerFontSize
                font.bold: true
                color: Utils.Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: {
                    const dev = Services.Bluetooth.connectedDevice;
                    if (!dev) return "";
                    const parts = ["Connected"];
                    if (dev.batteryAvailable)
                        parts.push(Math.round(dev.battery * 100) + "%");
                    return parts.join(" · ");
                }
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
            }
        }

        // Disconnected: single centered label
        Text {
            id: disconnectedHeader
            visible: !headerRow.isConnected
            text: Services.Bluetooth.powered ? "No device" : "Bluetooth off"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.headerFontSize
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
            font.pixelSize: Utils.Theme.headerActionIconSize
            color: disconnectMouse.containsMouse ? Utils.Theme.red : Utils.Theme.subtleText

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
                onClicked: {
                    const dev = Services.Bluetooth.connectedDevice;
                    if (dev) Services.Bluetooth.disconnectDevice(dev.address);
                }
            }
        }
    }

    // --- Separator ---
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
    }

    // --- Section header: "Devices" + scan button + power toggle ---
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Text {
            text: "Devices"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Utils.Theme.subtext0
            Layout.fillWidth: true
        }

        Utils.MaterialIcon {
            id: refreshIcon
            text: "refresh"
            font.pixelSize: Utils.Theme.headerActionIconSize
            color: refreshMouse.containsMouse ? Utils.Theme.text : Utils.Theme.subtleText
            visible: Services.Bluetooth.powered

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            RotationAnimation on rotation {
                running: Services.Bluetooth.scanning
                from: 0
                to: 360
                duration: Utils.Theme.animDurationSpin
                loops: Animation.Infinite
            }

            Connections {
                target: Services.Bluetooth
                function onScanningChanged() {
                    if (!Services.Bluetooth.scanning) refreshIcon.rotation = 0;
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Bluetooth.scan()
            }
        }

        Utils.MaterialIcon {
            text: Services.Bluetooth.powered ? "toggle_on" : "toggle_off"
            font.pixelSize: Utils.Theme.headerActionIconSize
            color: {
                if (powerMouse.containsMouse)
                    return Services.Bluetooth.powered ? Utils.Theme.red : Utils.Theme.accent;
                return Services.Bluetooth.powered ? Utils.Theme.accent : Utils.Theme.subtleText;
            }

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Bluetooth.togglePower()
            }
        }
    }

    // --- Device list ---
    Item {
        Layout.fillWidth: true
        implicitHeight: Utils.Theme.popoutListHeight
        clip: true

        ListView {
            id: deviceList
            anchors.fill: parent
            model: Services.Bluetooth.devices
            spacing: Utils.Theme.spacingTiny

            delegate: Rectangle {
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

                readonly property bool isConnecting: connecting
                readonly property bool isPairing: pairing
                readonly property bool isDisconnecting: disconnecting
                readonly property bool clickable: !connected && !isConnecting && !isPairing

                width: deviceList.width
                height: Utils.Theme.listItemHeight
                radius: Utils.Theme.listItemRadius
                color: "transparent"

                transform: Translate {
                    x: deviceDelegate.clickable && delegateMouse.containsMouse ? 4 : 0
                    Behavior on x { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutExpo } }
                }

                // Hover background
                Rectangle {
                    anchors.fill: parent
                    radius: Utils.Theme.listItemRadius
                    color: Utils.Theme.hoverBg
                    opacity: deviceDelegate.clickable && delegateMouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Utils.Theme.listItemMargin
                    anchors.rightMargin: Utils.Theme.listItemMargin
                    spacing: Utils.Theme.spacingNormal

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
                        visible: deviceDelegate.isConnecting || deviceDelegate.isDisconnecting || deviceDelegate.isPairing
                        text: deviceDelegate.isPairing ? "Pairing..." : deviceDelegate.isConnecting ? "Connecting..." : "Disconnecting..."
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.fontSizeSmall
                        font.italic: true
                        color: Utils.Theme.subtext0
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Connected check
                    Utils.MaterialIcon {
                        visible: deviceDelegate.connected && !deviceDelegate.isDisconnecting
                        text: "check"
                        font.pixelSize: Utils.Theme.headerFontSize
                        color: Utils.Theme.accent
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                opacity: 1.0

                MouseArea {
                    id: delegateMouse
                    anchors.fill: parent
                    hoverEnabled: deviceDelegate.clickable
                    cursorShape: deviceDelegate.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: deviceDelegate.clickable
                    onClicked: Services.Bluetooth.connectDevice(deviceDelegate.address)
                }
            }
        }

        // Empty state
        Text {
            visible: !Services.Bluetooth.devices || Services.Bluetooth.devices.count === 0
            anchors.centerIn: parent
            text: {
                if (!Services.Bluetooth.powered) return "Bluetooth is off";
                if (Services.Bluetooth.scanning) return "Scanning...";
                return "No devices found";
            }
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            font.italic: true
            color: Utils.Theme.subtleText
        }
    }

    // --- Separator ---
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
    }

    // --- Open bluetui pill button ---
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Utils.Theme.pillHeight
        radius: Utils.Theme.roundingFull
        color: Utils.Theme.pillBg
        border.width: 1
        border.color: bluetuiMouse.containsMouse ? Utils.Theme.surface2 : Utils.Theme.surface1

        Behavior on border.color {
            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Utils.Theme.hoverBg
            opacity: bluetuiMouse.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Utils.Theme.pillSpacing

            Utils.MaterialIcon {
                text: "terminal"
                font.pixelSize: Utils.Theme.iconSizeSmall
                color: Utils.Theme.subtext1
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Open bluetui"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.pillFontSize
                font.weight: Font.Medium
                color: Utils.Theme.subtext1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: bluetuiMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bluetuiProc.running = true
        }
    }

    Process {
        id: bluetuiProc
        command: ["sh", "-c", "setsid ghostty -e bluetui &"]
    }
}
