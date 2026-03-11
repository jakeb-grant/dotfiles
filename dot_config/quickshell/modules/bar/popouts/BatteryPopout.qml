import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal
    implicitWidth: 220

    // Battery percentage + status
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Battery.charging ? "battery_charging_full" : "battery_full"
            font.pixelSize: 28
            color: {
                if (Services.Battery.charging) return Utils.Theme.green;
                if (Services.Battery.percent < 20) return Utils.Theme.red;
                return Utils.Theme.yellow;
            }
        }

        ColumnLayout {
            spacing: 2

            Text {
                text: Services.Battery.percent + "%"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                color: Utils.Theme.text
            }

            Text {
                text: Services.Battery.charging ? "Charging" : "Discharging"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // Battery bar
    ColumnLayout {
        spacing: Utils.Theme.spacingSmall

        Text {
            text: "Capacity"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtext0
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Utils.Theme.surface0

            Rectangle {
                width: parent.width * Services.Battery.percentage
                height: parent.height
                radius: 4
                color: {
                    if (Services.Battery.percent < 20) return Utils.Theme.red;
                    if (Services.Battery.percent < 50) return Utils.Theme.yellow;
                    return Utils.Theme.green;
                }

                Behavior on width {
                    Utils.Anim {}
                }
            }
        }
    }

    // Volume
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Audio.muted ? "volume_off" : "volume_up"
            font.pixelSize: Utils.Theme.iconSize
            color: Services.Audio.muted ? Utils.Theme.overlay0 : Utils.Theme.blue
        }

        Text {
            text: Services.Audio.muted ? "Muted" : Services.Audio.volumePercent + "%"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text
        }
    }

    // Network
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Text {
            text: {
                if (Services.Network.state !== "connected") return "󰤮";
                const icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
                return icons[Services.Network.signalLevel];
            }
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.iconSize
            color: Services.Network.state === "connected" ? Utils.Theme.green : Utils.Theme.overlay0
        }

        Text {
            text: Services.Network.label
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text
        }
    }
}
