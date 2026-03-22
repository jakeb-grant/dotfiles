import Quickshell
import QtQuick
import qs.utils as Utils

Item {
    id: root

    required property ShellScreen screen

    readonly property int contentWidth: Utils.Theme.barWidth
    readonly property int contentHeight: Utils.Theme.barWidth
    readonly property int exclusiveZone: Utils.Theme.barWidth

    implicitWidth: Utils.Theme.isSide ? 0 : parent.width
    implicitHeight: Utils.Theme.isTop ? 0 : parent.height

    Rectangle {
        width: Utils.Theme.isSide ? root.implicitWidth : parent.width
        height: Utils.Theme.isTop ? root.implicitHeight : parent.height
        color: Utils.Theme.mantle
    }

    BarContent {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Utils.Theme.isSide ? Utils.Theme.barPadding : 0
        anchors.rightMargin: Utils.Theme.isSide ? Utils.Theme.barPadding : 0
        anchors.topMargin: Utils.Theme.isTop ? Utils.Theme.barPadding : 0
        anchors.bottomMargin: Utils.Theme.isTop ? Utils.Theme.barPadding : 0
        screen: root.screen
    }

    states: [
        State {
            name: "barSide"
            when: Utils.Theme.isSide
            PropertyChanges {
                root.implicitWidth: root.contentWidth
            }
        },
        State {
            name: "barTop"
            when: Utils.Theme.isTop
            PropertyChanges {
                root.implicitHeight: root.contentHeight
            }
        }
    ]

    transitions: [
        Transition {
            to: "barSide"
            Utils.Anim {
                target: root
                property: "implicitWidth"
            }
        },
        Transition {
            to: "barTop"
            Utils.Anim {
                target: root
                property: "implicitHeight"
            }
        }
    ]
}
