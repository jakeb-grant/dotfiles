import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

ColumnLayout {
    id: root

    required property string title
    required property string icon

    spacing: Utils.Theme.spacingNormal
    implicitWidth: 180

    Utils.MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: root.icon
        font.pixelSize: 32
        color: Utils.Theme.blue
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.title
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSize
        font.bold: true
        color: Utils.Theme.text
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Coming soon"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.overlay0
    }
}
