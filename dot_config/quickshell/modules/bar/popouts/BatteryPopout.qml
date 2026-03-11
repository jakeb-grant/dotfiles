import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: 280
        implicitHeight: 0
    }

    // Battery percentage + status
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Battery.icon
            font.pixelSize: 28
            color: Services.Battery.iconColor

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            spacing: 2

            Text {
                text: Services.Battery.percent + "%"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                color: Utils.Theme.text
            }

            Text {
                text: Services.Battery.charging ? "Charging" : "Discharging"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // Battery bar
    ColumnLayout {
        spacing: Utils.Theme.spacingSmall

        Text {
            text: "Capacity"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtext0
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Utils.Theme.surface0

            Rectangle {
                width: parent.width * Services.Battery.percentage
                height: parent.height
                radius: 4
                color: {
                    if (Services.Battery.percent < 20) return Utils.Theme.red;
                    if (Services.Battery.percent < 50) return Utils.Theme.yellow;
                    return Utils.Theme.green;
                }

                Behavior on width {
                    Utils.Anim {}
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    // Power profile
    ColumnLayout {
        spacing: Utils.Theme.spacingSmall

        Text {
            text: "Power Profile"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtext0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Utils.Theme.spacingSmall

            Repeater {
                model: [
                    { profile: "power-saver", label: "Saver", icon: "eco", accent: "green" },
                    { profile: "balanced", label: "Balanced", icon: "balance", accent: "blue" },
                    { profile: "performance", label: "Perf", icon: "bolt", accent: "peach" },
                ]

                Rectangle {
                    id: pill

                    required property var modelData

                    readonly property bool active: Services.Battery.powerProfile === modelData.profile
                    readonly property color accent: Utils.Theme[modelData.accent]

                    Layout.fillWidth: true
                    height: 30
                    radius: height / 2
                    color: active ? Utils.Theme.surface2 : (pillMouse.containsMouse ? Utils.Theme.surface1 : Utils.Theme.surface0)

                    Behavior on color {
                        ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Utils.MaterialIcon {
                            text: pill.modelData.icon
                            font.pixelSize: 14
                            color: pill.active ? pill.accent : Utils.Theme.overlay1
                        }

                        Text {
                            text: pill.modelData.label
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.fontSizeSmall
                            color: pill.active ? pill.accent : Utils.Theme.overlay1
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Battery.setProfile(pill.modelData.profile)
                    }
                }
            }
        }
    }

}
