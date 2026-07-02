import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

// Hoverable list row: slide-right + hover background when interactive.
// Children land in the inner RowLayout (icon, label, status, ...).
// Callers set width (ListView.view.width / parent.width) per delegate.
Rectangle {
    id: root

    property bool interactive: true
    // Horizontal inset of the hover background (tray menu uses spacingTiny)
    property real hoverPadding: 0
    readonly property alias hovered: mouse.containsMouse
    readonly property alias contentImplicitWidth: contentRow.implicitWidth
    default property alias content: contentRow.data

    signal clicked()

    height: Utils.Theme.listItemHeight
    radius: Utils.Theme.listItemRadius
    color: "transparent"

    transform: Translate {
        x: root.interactive && mouse.containsMouse ? 4 : 0
        Behavior on x { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutExpo } }
    }

    // Hover background
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: root.hoverPadding
        anchors.rightMargin: root.hoverPadding
        radius: Utils.Theme.listItemRadius
        color: Utils.Theme.hoverBg
        opacity: root.interactive && mouse.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Utils.Theme.listItemMargin
        anchors.rightMargin: Utils.Theme.listItemMargin
        spacing: Utils.Theme.spacingNormal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.interactive
        onClicked: root.clicked()
    }
}
