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

    Column {
        id: col

        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Services.Clock.hours
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSize
            font.bold: true
            color: Utils.Theme.teal
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Services.Clock.minutes
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSize
            font.bold: true
            color: Utils.Theme.subtext0
        }
    }
}
