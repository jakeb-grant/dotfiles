import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: 280
        implicitHeight: 0
    }

    // Header
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "power_settings_new"
            font.pixelSize: 24
            color: Utils.Theme.red
        }

        Text {
            text: "Power"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Utils.Theme.text
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // Action buttons
    Column {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: [
                { label: "Shut Down", icon: "power_settings_new", accent: "red", cmd: "systemctl poweroff" },
                { label: "Restart", icon: "restart_alt", accent: "peach", cmd: "systemctl reboot" },
                { label: "Sleep", icon: "bedtime", accent: "mauve", cmd: "systemctl suspend" },
                { label: "Lock Screen", icon: "lock", accent: "blue", cmd: "loginctl lock-session" },
                { label: "Log Out", icon: "logout", accent: "yellow", cmd: "hyprctl dispatch exit" },
            ]

            Rectangle {
                id: actionItem

                required property var modelData

                width: parent?.width ?? 0
                height: 36
                radius: 6
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Utils.Theme.surface1
                    opacity: actionMouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: Utils.Theme.spacingNormal

                    Utils.MaterialIcon {
                        text: actionItem.modelData.icon
                        font.pixelSize: 18
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
