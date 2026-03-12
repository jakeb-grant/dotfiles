import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: root

    required property ShellScreen screen

    implicitWidth: Utils.Theme.barInnerWidth
    implicitHeight: col.implicitHeight + Utils.Theme.spacingNormal * 2
    radius: Utils.Theme.roundingNormal
    color: Utils.Theme.pillBg

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: Utils.Theme.spacingSmall

        // Volume
        Item {
            id: volumeItem

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: volumeIcon.implicitWidth
            implicitHeight: volumeIcon.implicitHeight

            Utils.MaterialIcon {
                id: volumeIcon
                anchors.centerIn: parent
                text: {
                    const v = Services.Audio.volumePercent;
                    if (Services.Audio.muted) return "volume_off";
                    if (v === 0) return "volume_mute";
                    if (v <= 25) return "volume_down";
                    return "volume_up";
                }
                fill: Services.Audio.muted ? 0 : 1
                font.pixelSize: Utils.Theme.iconSize
                color: {
                    const v = Services.Audio.volumePercent;
                    if (Services.Audio.muted || v === 0) return Utils.Theme.disabledText;
                    if (v <= 15) return Utils.Theme.subtext0;
                    if (v <= 35) return Utils.Theme.lavender;
                    if (v <= 60) return Utils.Theme.blue;
                    if (v <= 85) return Utils.Theme.teal;
                    return Utils.Theme.green;
                }

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    const globalPos = volumeItem.mapToGlobal(0, volumeItem.height / 2);
                    Services.Popout.show("volume", globalPos.y, root.screen);
                }
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Wifi
        Item {
            id: wifiItem

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: wifiIcon.implicitWidth
            implicitHeight: wifiIcon.implicitHeight

            Text {
                id: wifiIcon
                anchors.centerIn: parent
                text: {
                    if (Services.Network.state !== "connected") return "󰤮";
                    const icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
                    return icons[Services.Network.signalLevel];
                }
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.iconSize
                color: Services.Network.state === "connected" ? Utils.Theme.green : Utils.Theme.disabledText

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    const globalPos = wifiItem.mapToGlobal(0, wifiItem.height / 2);
                    Services.Popout.show("wifi", globalPos.y, root.screen);
                }
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Bluetooth
        Item {
            id: bluetoothItem

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: bluetoothIcon.implicitWidth
            implicitHeight: bluetoothIcon.implicitHeight

            Utils.MaterialIcon {
                id: bluetoothIcon
                anchors.centerIn: parent
                text: {
                    if (!Services.Bluetooth.powered) return "bluetooth_disabled";
                    if (Services.Bluetooth.connectedDevice) return "bluetooth_connected";
                    return "bluetooth";
                }
                fill: 1
                font.pixelSize: Utils.Theme.iconSize
                color: {
                    if (!Services.Bluetooth.powered) return Utils.Theme.disabledText;
                    if (Services.Bluetooth.connectedDevice) return Utils.Theme.blue;
                    return Utils.Theme.subtleText;
                }

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    const globalPos = bluetoothItem.mapToGlobal(0, bluetoothItem.height / 2);
                    Services.Popout.show("bluetooth", globalPos.y, root.screen);
                }
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Battery
        Item {
            id: batteryItem

            Layout.alignment: Qt.AlignHCenter
            visible: Services.Battery.isLaptop
            implicitWidth: batteryIcon.implicitWidth
            implicitHeight: batteryIcon.implicitHeight

            Utils.MaterialIcon {
                id: batteryIcon
                anchors.centerIn: parent
                fill: 1
                text: Services.Battery.icon
                font.pixelSize: Utils.Theme.iconSize
                color: Services.Battery.iconColor

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    const globalPos = batteryItem.mapToGlobal(0, batteryItem.height / 2);
                    Services.Popout.show("battery", globalPos.y, root.screen);
                }
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }
    }
}
