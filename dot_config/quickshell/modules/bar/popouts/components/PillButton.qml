import QtQuick
import qs.utils as Utils

// Full-width footer pill button ("Open Impala", "Back", ...).
// Callers set Layout.fillWidth: true.
Rectangle {
    id: root

    property string icon
    property string label

    signal clicked()

    implicitHeight: Utils.Theme.pillHeight
    radius: Utils.Theme.roundingFull
    color: Utils.Theme.pillBg
    border.width: 1
    border.color: mouse.containsMouse ? Utils.Theme.surface2 : Utils.Theme.surface1

    Behavior on border.color {
        ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
    }

    // Hover fill
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Utils.Theme.hoverBg
        opacity: mouse.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: Utils.Theme.pillSpacing

        Utils.MaterialIcon {
            text: root.icon
            font.pixelSize: Utils.Theme.iconSizeSmall
            color: Utils.Theme.subtext1
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.label
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.pillFontSize
            font.weight: Font.Medium
            color: Utils.Theme.subtext1
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
