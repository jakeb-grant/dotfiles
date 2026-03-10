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
    color: Utils.Theme.surface0

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
                text: Services.Audio.muted ? "volume_off" : Services.Audio.volumePercent > 50 ? "volume_up" : "volume_down"
                fill: Services.Audio.muted ? 0 : 1
                font.pixelSize: Utils.Theme.iconSize
                color: Services.Audio.muted ? Utils.Theme.overlay0 : Utils.Theme.blue
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Audio.toggleMute()

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

        // Network
        Utils.MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: Services.Network.state === "connected" ? "wifi" : "wifi_off"
            fill: Services.Network.state === "connected" ? 1 : 0
            font.pixelSize: Utils.Theme.iconSize
            color: Services.Network.state === "connected" ? Utils.Theme.green : Utils.Theme.overlay0
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
                text: {
                    if (Services.Battery.charging) return "battery_charging_full";
                    if (Services.Battery.percent > 75) return "battery_full";
                    if (Services.Battery.percent > 50) return "battery_5_bar";
                    if (Services.Battery.percent > 25) return "battery_3_bar";
                    return "battery_1_bar";
                }
                font.pixelSize: Utils.Theme.iconSize
                color: {
                    if (Services.Battery.charging) return Utils.Theme.green;
                    if (Services.Battery.percent < 20) return Utils.Theme.red;
                    return Utils.Theme.yellow;
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
