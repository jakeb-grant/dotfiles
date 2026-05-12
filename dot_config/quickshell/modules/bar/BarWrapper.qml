import Quickshell
import QtQuick
import QtQuick.Effects
import qs.utils as Utils

Item {
    id: root

    required property ShellScreen screen

    readonly property int exclusiveZone: Utils.Theme.barMargin + Utils.Theme.barWidth

    // Used by Drawers.qml/PopoutWrapper.qml to find the bar's thickness axis.
    implicitWidth: Utils.Theme.isSide ? Utils.Theme.barWidth : parent.width
    implicitHeight: Utils.Theme.isTop ? Utils.Theme.barWidth : parent.height

    Rectangle {
        anchors.fill: parent
        color: Utils.Theme.mantle
        radius: Utils.Theme.barRounding

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Utils.Theme.islandShadowColor
            shadowOpacity: Utils.Theme.islandShadowOpacity
            blurMax: Utils.Theme.islandShadowBlur
            shadowVerticalOffset: Utils.Theme.islandShadowY
            shadowHorizontalOffset: 0
            autoPaddingEnabled: true
        }
    }

    BarContent {
        anchors.fill: parent
        anchors.leftMargin: Utils.Theme.isSide ? Utils.Theme.barPadding : 0
        anchors.rightMargin: Utils.Theme.isSide ? Utils.Theme.barPadding : 0
        anchors.topMargin: Utils.Theme.isTop ? Utils.Theme.barPadding : 0
        anchors.bottomMargin: Utils.Theme.isTop ? Utils.Theme.barPadding : 0
        screen: root.screen
    }
}
