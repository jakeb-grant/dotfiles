import QtQuick
import qs.utils as Utils

// Hoverable icon button. The root IS a MaterialIcon, so callers set `text`
// and `font.pixelSize` directly. Disabling the button (enabled: false) also
// disables the internal MouseArea via normal QML enabled propagation.
Utils.MaterialIcon {
    id: root

    property color baseColor: Utils.Theme.subtleText
    property color hoverColor: Utils.Theme.text
    property color disabledColor: Utils.Theme.disabledText
    // Press/hover scale feedback (transport-style buttons)
    property bool bounce: false
    // Extra hit area beyond the glyph bounds, in px
    property real hitPadding: 0
    readonly property alias hovered: mouse.containsMouse
    readonly property alias pressed: mouse.pressed

    signal clicked()

    color: !enabled ? disabledColor : mouse.containsMouse ? hoverColor : baseColor
    scale: bounce && enabled ? (mouse.pressed ? 0.85 : mouse.containsMouse ? 1.1 : 1) : 1

    Behavior on color {
        ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation {
            duration: mouse.pressed ? 50 : 250
            easing.type: mouse.pressed ? Easing.OutQuad : Easing.OutBack
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -root.hitPadding
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
