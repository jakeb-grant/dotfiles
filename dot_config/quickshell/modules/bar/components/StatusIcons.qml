import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: root

    implicitWidth: Utils.Theme.barInnerWidth
    implicitHeight: col.implicitHeight + Utils.Theme.spacingNormal * 2
    radius: Utils.Theme.roundingNormal
    color: Utils.Theme.surface0

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: Utils.Theme.spacingSmall

        // Volume
        Utils.MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: Services.Audio.muted ? "volume_off" : Services.Audio.volumePercent > 50 ? "volume_up" : "volume_down"
            fill: Services.Audio.muted ? 0 : 1
            font.pixelSize: Utils.Theme.iconSize
            color: Services.Audio.muted ? Utils.Theme.overlay0 : Utils.Theme.blue

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Audio.toggleMute()
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
        Utils.MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            visible: Services.Battery.isLaptop
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
    }
}
