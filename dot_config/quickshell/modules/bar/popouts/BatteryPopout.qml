import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    property real _flowOffset: 0
    NumberAnimation on _flowOffset { from: 0; to: 1; duration: 8000; loops: Animation.Infinite }

    // Width spacer
    Item {
        implicitWidth: Utils.Theme.popoutWidth
        implicitHeight: 0
    }

    // Battery percentage + status
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Battery.icon
            font.pixelSize: Utils.Theme.headerIconSizeLarge
            color: Services.Battery.iconColor

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            spacing: Utils.Theme.spacingTiny

            Text {
                text: Services.Battery.percent + "%"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.popoutTitleSize
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
        color: Utils.Theme.separator
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
            color: Utils.Theme.pillBg

            Item {
                id: batFill
                width: parent.width * Services.Battery.percentage
                height: parent.height

                readonly property color batColor1: {
                    if (Services.Battery.percent < 20) return Utils.Theme.red;
                    if (Services.Battery.percent < 50) return Utils.Theme.yellow;
                    return Utils.Theme.green;
                }
                readonly property color batColor2: {
                    if (Services.Battery.percent < 20) return Utils.Theme.maroon;
                    if (Services.Battery.percent < 50) return Utils.Theme.peach;
                    return Utils.Theme.teal;
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: batFillMask
                }

                Rectangle {
                    id: batFillMask
                    anchors.fill: parent
                    radius: 4
                    visible: false
                    layer.enabled: true
                }

                Rectangle {
                    width: 2000
                    height: parent.height
                    x: -(root._flowOffset * 1000)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.000; color: batFill.batColor1 }
                        GradientStop { position: 0.167; color: batFill.batColor2 }
                        GradientStop { position: 0.333; color: batFill.batColor1 }
                        GradientStop { position: 0.500; color: batFill.batColor2 }
                        GradientStop { position: 0.667; color: batFill.batColor1 }
                        GradientStop { position: 0.833; color: batFill.batColor2 }
                        GradientStop { position: 1.000; color: batFill.batColor1 }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: 1200; easing.type: Easing.OutQuint }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
    }

    // Power profile
    ColumnLayout {
        spacing: Utils.Theme.spacingSmall

        Text {
            text: "Power Profile: " + segmentedSlider.profiles[segmentedSlider.activeIndex].label
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtext0
        }

        // Segmented slider
        Rectangle {
            id: segmentedSlider

            readonly property var profiles: [
                { profile: "power-saver", label: "Power Saver", icon: "eco", accent: "green" },
                { profile: "balanced", label: "Balanced", icon: "balance", accent: "blue" },
                { profile: "performance", label: "Performance", icon: "bolt", accent: "peach" },
            ]
            readonly property int activeIndex: {
                for (let i = 0; i < profiles.length; i++)
                    if (profiles[i].profile === Services.Battery.powerProfile) return i;
                return 1;
            }
            readonly property real segmentWidth: (width - 6) / 3

            Layout.fillWidth: true
            height: 38
            radius: height / 2
            color: Utils.Theme.pillBg

            // Sliding highlight
            Rectangle {
                x: 3 + segmentedSlider.activeIndex * segmentedSlider.segmentWidth
                y: 3
                width: segmentedSlider.segmentWidth
                height: parent.height - 6
                radius: height / 2
                color: Utils.Theme.surface2

                Behavior on x {
                    NumberAnimation { duration: Utils.Theme.animDuration; easing.type: Easing.OutExpo }
                }
            }

            // Icon segments
            Row {
                anchors.fill: parent
                anchors.leftMargin: 3
                anchors.rightMargin: 3

                Repeater {
                    model: segmentedSlider.profiles

                    Item {
                        required property var modelData
                        required property int index

                        readonly property bool active: index === segmentedSlider.activeIndex
                        readonly property color accent: Utils.Theme[modelData.accent]

                        width: segmentedSlider.segmentWidth
                        height: parent.height

                        Utils.MaterialIcon {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: Utils.Theme.iconSize
                            color: active ? accent : Utils.Theme.subtleText

                            Behavior on color {
                                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Battery.setProfile(modelData.profile)
                        }
                    }
                }
            }
        }

    }

}
