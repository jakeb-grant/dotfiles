import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingSmall

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Services.Clock.format("dddd")
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSize
        font.bold: true
        color: Utils.Theme.blue
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Services.Clock.format("MMMM d, yyyy")
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtext0
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Services.Clock.format("hh:mm:ss")
        font.family: Utils.Theme.fontFamily
        font.pixelSize: 24
        font.bold: true
        color: Utils.Theme.teal
    }
}
