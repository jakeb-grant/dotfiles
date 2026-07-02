import QtQuick
import QtQuick.Effects
import qs.utils as Utils

// Track + masked flowing-gradient fill (sliders, seek bars, battery bar).
// `flowColors` (2 or 3 colors) cycles across 7 gradient stops; the flow
// animation shifts by one full pattern period per loop so the wrap is
// seamless for either count.
Rectangle {
    id: root

    // Fill fraction 0..1
    property real ratio: 0
    property list<color> flowColors: [Utils.Theme.accent, Utils.Theme.mauve, Utils.Theme.lavender]
    // Flat fill override (e.g. muted volume)
    property bool flatFill: false
    property color flatColor: Utils.Theme.subtleText
    property bool animateWidth: true
    property int widthAnimDuration: Utils.Theme.animDurationFast
    property int widthAnimEasing: Easing.OutCubic

    property real _flowOffset: 0
    NumberAnimation on _flowOffset { from: 0; to: 1; duration: 8000; loops: Animation.Infinite }

    // One full color-pattern period in px (stops sit 2000/6 apart). Shifting by
    // exactly one period per loop keeps the wrap seamless for any color count.
    readonly property real _flowPeriod: 2000 / 6 * flowColors.length

    radius: height / 2
    color: Utils.Theme.pillBg

    Item {
        width: parent.width * root.ratio
        height: parent.height

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: fillMask
        }

        Rectangle {
            id: fillMask
            anchors.fill: parent
            radius: root.radius
            visible: false
            layer.enabled: true
        }

        // Flat fallback
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.flatColor
            visible: root.flatFill
        }

        // Flowing gradient
        Rectangle {
            visible: !root.flatFill
            width: 2000
            height: parent.height
            x: -(root._flowOffset * root._flowPeriod)

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.000; color: root.flowColors[0] }
                GradientStop { position: 0.167; color: root.flowColors[1 % root.flowColors.length] }
                GradientStop { position: 0.333; color: root.flowColors[2 % root.flowColors.length] }
                GradientStop { position: 0.500; color: root.flowColors[3 % root.flowColors.length] }
                GradientStop { position: 0.667; color: root.flowColors[4 % root.flowColors.length] }
                GradientStop { position: 0.833; color: root.flowColors[5 % root.flowColors.length] }
                GradientStop { position: 1.000; color: root.flowColors[6 % root.flowColors.length] }
            }
        }

        Behavior on width {
            enabled: root.animateWidth
            NumberAnimation { duration: root.widthAnimDuration; easing.type: root.widthAnimEasing }
        }
    }
}
