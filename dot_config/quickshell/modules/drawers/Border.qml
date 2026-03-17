import QtQuick
import QtQuick.Effects
import qs.utils as Utils

Item {
    id: root

    required property Item bar

    anchors.fill: parent
    visible: Utils.Theme.borderThickness > 0

    Rectangle {
        anchors.fill: parent
        color: Utils.Theme.mantle

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }


    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Utils.Theme.borderThickness
            anchors.leftMargin: root.bar.implicitWidth
            radius: Utils.Theme.borderRounding
        }
    }

}
