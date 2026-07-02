import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    // The profile can change behind our back (keybind, TLP) — re-poll on open
    Component.onCompleted: Services.Battery.refreshProfile()

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

    Separator {}

    // Battery bar
    ColumnLayout {
        spacing: Utils.Theme.spacingSmall

        SectionLabel {
            text: "Capacity"
        }

        FlowBar {
            Layout.fillWidth: true
            height: 8
            ratio: Services.Battery.percentage
            widthAnimDuration: 1200
            widthAnimEasing: Easing.OutQuint
            flowColors: {
                if (Services.Battery.percent < 20) return [Utils.Theme.red, Utils.Theme.maroon];
                if (Services.Battery.percent < 50) return [Utils.Theme.yellow, Utils.Theme.peach];
                return [Utils.Theme.green, Utils.Theme.teal];
            }
        }
    }

    Separator {}

    // Power profile
    ColumnLayout {
        spacing: Utils.Theme.spacingSmall

        SectionLabel {
            text: "Power Profile: " + segmentedSlider.profiles[segmentedSlider.activeIndex].label
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
