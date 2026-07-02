import QtQuick
import qs.utils as Utils

// Interactive flowing-gradient slider: FlowBar track + thumb + drag handling.
// The slider is display-only — callers own the value: bind `value`, apply
// `moved(newValue)` to their service, and use pressStarted/released for
// grab/resync protocols.
Item {
    id: root

    // Displayed position 0..1
    property real value: 0
    property alias flowColors: bar.flowColors
    property alias flatFill: bar.flatFill
    property alias flatColor: bar.flatColor
    property real trackHeight: Utils.Theme.sliderTrackHeight
    property real thumbSize: Utils.Theme.sliderThumbSize
    property bool thumbVisible: true
    // Press/hover scale feedback on the thumb (off for slim seek bars)
    property bool thumbBounce: true
    readonly property bool dragging: mouse.pressed
    readonly property real effectiveWidth: width - thumbSize

    signal pressStarted()
    signal moved(real newValue)
    signal released()

    implicitHeight: Utils.Theme.sliderHeight

    FlowBar {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.thumbSize / 2
        anchors.rightMargin: root.thumbSize / 2
        height: root.trackHeight
        ratio: root.value
        animateWidth: !root.dragging
    }

    // Thumb
    Rectangle {
        x: root.thumbSize / 2 + root.effectiveWidth * root.value - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.thumbSize
        height: root.thumbSize
        radius: width / 2
        color: mouse.containsMouse || mouse.pressed ? Utils.Theme.text : Utils.Theme.subtext0
        scale: root.thumbBounce ? (mouse.pressed ? 1.4 : mouse.containsMouse ? 1.15 : 1) : 1
        visible: root.thumbVisible

        Behavior on x {
            enabled: !root.dragging
            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation {
                duration: mouse.pressed ? 80 : Utils.Theme.animDurationFast
                easing.type: mouse.pressed ? Easing.OutQuad : Easing.OutBack
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        function valueFromX(mouseX: real): void {
            const clamped = Math.max(root.thumbSize / 2,
                Math.min(mouseX, root.width - root.thumbSize / 2));
            root.moved((clamped - root.thumbSize / 2) / root.effectiveWidth);
        }

        onPressed: (event) => { root.pressStarted(); valueFromX(event.x); }
        onPositionChanged: (event) => { if (pressed) valueFromX(event.x); }
        onReleased: root.released()
        onCanceled: root.released()
    }
}
