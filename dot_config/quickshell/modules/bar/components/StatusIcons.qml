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

            Utils.MaterialIcon {
                id: volumeIcon
                anchors.centerIn: parent
                text: Services.Audio.icon
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

                onEntered: Services.Popout.showFrom(volumeItem, "volume", root.screen)
                onExited: Services.Popout.barItemExited()
            }
        }

        // Brightness
        Item {
            id: brightnessItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            visible: Services.Brightness.available
            implicitWidth: brightnessIcon.implicitWidth
            implicitHeight: brightnessIcon.implicitHeight

            Utils.MaterialIcon {
                id: brightnessIcon
                anchors.centerIn: parent
                text: Services.Brightness.icon
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

                onEntered: Services.Popout.showFrom(brightnessItem, "brightness", root.screen)
                onExited: Services.Popout.barItemExited()
            }
        }

        // Wifi
        Item {
            id: wifiItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
            implicitWidth: wifiIcon.implicitWidth
            implicitHeight: wifiIcon.implicitHeight

            Text {
                id: wifiIcon
                anchors.centerIn: parent
                text: Services.Network.signalIcon
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

                onEntered: Services.Popout.showFrom(wifiItem, "wifi", root.screen)
                onExited: Services.Popout.barItemExited()
            }
        }

        // Bluetooth
        Item {
            id: bluetoothItem

            Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
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

                onEntered: Services.Popout.showFrom(bluetoothItem, "bluetooth", root.screen)
                onExited: Services.Popout.barItemExited()
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
                    to: batteryItem._isDanger ? 1.04 : 1.01
                    duration: batteryItem._isDanger ? 600 : 2500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: batteryItem._isDanger ? 600 : 2500
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

                onEntered: Services.Popout.showFrom(batteryItem, "battery", root.screen)
                onExited: Services.Popout.barItemExited()
            }
        }
    }
}
