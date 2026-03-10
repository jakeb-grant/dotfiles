import Quickshell
import QtQuick
import qs.utils as Utils

Item {
    id: root

    required property ShellScreen screen

    readonly property int contentWidth: Utils.Theme.barWidth
    readonly property int exclusiveZone: contentWidth

    implicitWidth: 0

    Rectangle {
        width: root.implicitWidth
        height: parent.height
        color: Utils.Theme.mantle
    }

    BarContent {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Utils.Theme.barPadding
        anchors.rightMargin: Utils.Theme.barPadding
        screen: root.screen
    }

    states: State {
        name: "visible"
        when: true

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: Transition {
        Utils.Anim {
            target: root
            property: "implicitWidth"
        }
    }
}
