import Quickshell.Services.SystemTray
import QtQuick
import qs.utils as Utils

Rectangle {
    id: root

    required property SystemTrayItem modelData

    implicitWidth: Utils.Theme.iconSize + 4
    implicitHeight: Utils.Theme.iconSize + 4
    radius: Utils.Theme.roundingSmall
    color: hover.containsMouse ? Utils.Theme.surface1 : "transparent"

    scale: hover.pressed ? 0.85 : (hover.containsMouse ? 1.15 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: hover.pressed ? 50 : 250
            easing.type: hover.pressed ? Easing.OutQuad : Easing.OutBack
        }
    }
    Behavior on color { ColorAnimation { duration: 200 } }

    Image {
        id: trayIcon
        anchors.centerIn: parent
        source: root.modelData.icon
        width: Utils.Theme.iconSize
        height: Utils.Theme.iconSize
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }

    Utils.MaterialIcon {
        anchors.centerIn: parent
        text: "apps"
        font.pixelSize: Utils.Theme.iconSize
        color: Utils.Theme.subtleText
        visible: !trayIcon.visible
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.modelData.secondaryActivate();
            else
                root.modelData.activate();
        }
    }
}
