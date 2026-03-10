import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal
    implicitWidth: 220

    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Audio.muted ? "volume_off" : "volume_up"
            font.pixelSize: 28
            color: Services.Audio.muted ? Utils.Theme.overlay0 : Utils.Theme.blue
        }

        Text {
            text: Services.Audio.muted ? "Muted" : Services.Audio.volumePercent + "%"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Utils.Theme.text
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // Volume bar
    Rectangle {
        Layout.fillWidth: true
        height: 8
        radius: 4
        color: Utils.Theme.surface0

        Rectangle {
            width: parent.width * Services.Audio.volume
            height: parent.height
            radius: 4
            color: Services.Audio.muted ? Utils.Theme.overlay0 : Utils.Theme.blue

            Behavior on width {
                Utils.Anim {}
            }
        }
    }

    // Mute toggle hint
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "click icon to " + (Services.Audio.muted ? "unmute" : "mute")
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.overlay0
    }
}
