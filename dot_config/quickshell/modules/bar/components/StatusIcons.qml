import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: root

    required property ShellScreen screen

    implicitWidth: Utils.Theme.isSide ? Utils.Theme.barInnerWidth : (layout.implicitWidth + Utils.Theme.spacingNormal * 2)
    implicitHeight: Utils.Theme.isTop ? Utils.Theme.barInnerWidth : (layout.implicitHeight + Utils.Theme.spacingNormal * 2)
    radius: Utils.Theme.roundingNormal
    color: Utils.Theme.pillBg

    function _showPopout(item: Item, name: string) {
        const gp = Utils.Theme.isSide
            ? item.mapToItem(null, 0, item.height / 2)
            : item.mapToItem(null, item.width / 2, 0);
        Services.Popout.show(name,
            Utils.Theme.isTop ? gp.x : 0,
            Utils.Theme.isSide ? gp.y : 0,
            root.screen);
    }

    GridLayout {
        id: layout

        anchors.centerIn: parent
        flow: Utils.Theme.isSide ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: Utils.Theme.isTop ? -1 : 1
        rows: Utils.Theme.isSide ? -1 : 1
        columnSpacing: Utils.Theme.isTop ? Utils.Theme.spacingSmall : 0
        rowSpacing: Utils.Theme.isSide ? Utils.Theme.spacingSmall : 0

        // Volume
        Item {
            id: volumeItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            implicitWidth: volumeIcon.implicitWidth
            implicitHeight: volumeIcon.implicitHeight

            scale: volumeMouse.containsMouse ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

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
                color: Utils.Theme.subtleText

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: volumeMouse
                anchors.fill: parent
                hoverEnabled: true

                onEntered: root._showPopout(volumeItem, "volume")
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Brightness
        Item {
            id: brightnessItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            visible: Services.Brightness.available
            implicitWidth: brightnessIcon.implicitWidth
            implicitHeight: brightnessIcon.implicitHeight

            scale: brightnessMouse.containsMouse ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            Utils.MaterialIcon {
                id: brightnessIcon
                anchors.centerIn: parent
                text: {
                    const p = Services.Brightness.percent;
                    if (p <= 14) return "brightness_1";
                    if (p <= 28) return "brightness_2";
                    if (p <= 42) return "brightness_3";
                    if (p <= 56) return "brightness_4";
                    if (p <= 70) return "brightness_5";
                    if (p <= 85) return "brightness_6";
                    return "brightness_7";
                }
                fill: 1
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtleText

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: brightnessMouse
                anchors.fill: parent
                hoverEnabled: true

                onEntered: root._showPopout(brightnessItem, "brightness")
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Wifi
        Item {
            id: wifiItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            implicitWidth: wifiIcon.implicitWidth
            implicitHeight: wifiIcon.implicitHeight

            scale: wifiMouse.containsMouse ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

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
                color: Utils.Theme.subtleText

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true

                onEntered: root._showPopout(wifiItem, "wifi")
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Bluetooth
        Item {
            id: bluetoothItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            implicitWidth: bluetoothIcon.implicitWidth
            implicitHeight: bluetoothIcon.implicitHeight

            scale: bluetoothMouse.containsMouse ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

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
                color: Services.Bluetooth.connectedDevice
                    ? Utils.Theme.accent : Utils.Theme.subtleText

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: bluetoothMouse
                anchors.fill: parent
                hoverEnabled: true

                onEntered: root._showPopout(bluetoothItem, "bluetooth")
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }

        // Battery
        Item {
            id: batteryItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            visible: Services.Battery.isLaptop
            implicitWidth: batteryIcon.implicitWidth
            implicitHeight: batteryIcon.implicitHeight

            property bool _isDanger: Services.Battery.percent < 15 && !Services.Battery.charging

            SequentialAnimation on scale {
                loops: Animation.Infinite; running: true
                NumberAnimation {
                    to: batteryMouse.containsMouse ? 1.05 : (batteryItem._isDanger ? 1.04 : 1.01)
                    duration: batteryMouse.containsMouse ? 1200 : (batteryItem._isDanger ? 600 : 2500)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: batteryMouse.containsMouse ? 1200 : (batteryItem._isDanger ? 600 : 2500)
                    easing.type: Easing.InOutSine
                }
            }

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
                id: batteryMouse
                anchors.fill: parent
                hoverEnabled: true

                onEntered: root._showPopout(batteryItem, "battery")
                onExited: {
                    Services.Popout.barItemHovered = false;
                    Services.Popout.requestClose();
                }
            }
        }
    }
}
