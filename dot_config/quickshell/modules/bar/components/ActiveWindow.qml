import QtQuick
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    implicitWidth: Utils.Theme.barInnerWidth
    clip: true

    Text {
        id: label

        anchors.centerIn: parent
        width: root.height
        text: Services.Hypr.activeWindowTitle || "Desktop"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtext0
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        rotation: 270
    }
}
