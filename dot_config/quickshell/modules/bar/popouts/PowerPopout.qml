import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: Utils.Theme.popoutWidth
        implicitHeight: 0
    }

    // Header
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "power_settings_new"
            font.pixelSize: Utils.Theme.headerIconSize
            color: Utils.Theme.red
        }

        Text {
            text: "Power"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
    }

    // Action buttons
    Column {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingTiny

        Repeater {
            model: [
                { label: "Shut Down", icon: "power_settings_new", accent: "red", cmd: "systemctl poweroff" },
                { label: "Restart", icon: "restart_alt", accent: "red", cmd: "systemctl reboot" },
                { label: "Sleep", icon: "bedtime", accent: "subtleText", cmd: "systemctl suspend" },
                { label: "Lock Screen", icon: "lock", accent: "subtleText", cmd: "loginctl lock-session" },
                { label: "Log Out", icon: "logout", accent: "red", cmd: "hyprctl dispatch exit" },
            ]

            Rectangle {
                id: actionItem

                required property var modelData

                width: parent?.width ?? 0
                height: Utils.Theme.actionItemHeight
                radius: Utils.Theme.listItemRadius
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: Utils.Theme.listItemRadius
                    color: Utils.Theme.hoverBg
                    opacity: actionMouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Utils.Theme.listItemMargin
                    anchors.rightMargin: Utils.Theme.listItemMargin
                    spacing: Utils.Theme.spacingNormal

                    Utils.MaterialIcon {
                        text: actionItem.modelData.icon
                        font.pixelSize: Utils.Theme.headerFontSize
                        color: Utils.Theme[actionItem.modelData.accent]
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: actionItem.modelData.label
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.fontSize
                        color: Utils.Theme.text
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        actionProc.command = ["sh", "-c", actionItem.modelData.cmd];
                        actionProc.running = true;
                    }
                }

                Process {
                    id: actionProc
                }
            }
        }
    }
}
