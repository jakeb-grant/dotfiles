import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    // Uptime + package counts go stale while the shell runs; statics are cached
    Component.onCompleted: Services.SystemInfo.refresh()

    // Distro + kernel
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "desktop_windows"
            font.pixelSize: Utils.Theme.headerIconSize
            color: Utils.Theme.accent
        }

        ColumnLayout {
            spacing: Utils.Theme.spacingTiny

            Text {
                text: "Arch Linux"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.popoutTitleSize
                font.bold: true
                color: Utils.Theme.text
            }

            Text {
                text: "kernel " + Services.SystemInfo.kernel
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
            }
        }
    }

    Separator {}

    // Uptime
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "schedule"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: Services.SystemInfo.uptime
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text
        }
    }

    // Host
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "computer"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: Services.SystemInfo.hostname
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text
        }
    }

    // Shell
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "terminal"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: Services.SystemInfo.shell
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text
        }
    }

    // Packages
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "inventory_2"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: Services.SystemInfo.pkgNative + " native, " + Services.SystemInfo.pkgAur + " AUR"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text
        }
    }

    Separator {}

    // ── Hardware Stats ──
    SectionLabel {
        text: "Hardware"
    }

    StatBar {
        icon: "memory"
        label: "CPU"
        value: Services.SystemStats.cpuPercent + "%"
        percent: Services.SystemStats.cpuPercent
    }

    StatBar {
        icon: "storage"
        label: "RAM"
        value: Services.SystemStats.memUsedGb.toFixed(1) + " / " + Services.SystemStats.memTotalGb.toFixed(1) + " GB"
        percent: Services.SystemStats.memPercent
    }

    StatBar {
        icon: "thermostat"
        label: "Temp"
        value: Services.SystemStats.cpuTemp + "\u00b0C"
        percent: Math.min(100, Services.SystemStats.cpuTemp)
        thresholdLow: 70
        thresholdHigh: 90
    }

    StatBar {
        icon: "hard_drive"
        label: "Disk"
        value: Services.SystemStats.diskUsed + " / " + Services.SystemStats.diskTotal
        percent: Services.SystemStats.diskPercent
    }

    // ── GPU (conditional) ──
    Separator {
        visible: Services.SystemStats.gpuAvailable
    }

    SectionLabel {
        text: "GPU"
        visible: Services.SystemStats.gpuAvailable
    }

    StatBar {
        visible: Services.SystemStats.gpuAvailable
        icon: "speed"
        label: "Usage"
        value: Services.SystemStats.gpuPercent + "%"
        percent: Services.SystemStats.gpuPercent
    }

    StatBar {
        visible: Services.SystemStats.gpuAvailable
        icon: "thermostat"
        label: "Temp"
        value: Services.SystemStats.gpuTemp + "\u00b0C"
        percent: Math.min(100, Services.SystemStats.gpuTemp)
        thresholdLow: 70
        thresholdHigh: 90
    }

    StatBar {
        visible: Services.SystemStats.gpuAvailable && Services.SystemStats.gpuType !== "intel"
        icon: "storage"
        label: "VRAM"
        value: Services.SystemStats.gpuMemUsed + " / " + Services.SystemStats.gpuMemTotal
        percent: Services.SystemStats.gpuMemPercent
    }

    component StatBar: ColumnLayout {
        id: stat

        required property string icon
        required property string label
        required property string value
        required property int percent
        property int thresholdLow: 50
        property int thresholdHigh: 80

        Layout.fillWidth: true
        spacing: Utils.Theme.spacingSmall

        readonly property color barColor: percent < thresholdLow
            ? Utils.Theme.green
            : percent < thresholdHigh
                ? Utils.Theme.yellow
                : Utils.Theme.red

        RowLayout {
            spacing: Utils.Theme.spacingNormal

            Utils.MaterialIcon {
                text: stat.icon
                font.pixelSize: Utils.Theme.iconSize
                color: stat.barColor

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: stat.label
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
            }

            Item { Layout.fillWidth: true }

            Text {
                text: stat.value
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                font.bold: true
                color: Utils.Theme.text
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Utils.Theme.sliderTrackHeight
            radius: height / 2
            color: Utils.Theme.pillBg

            Rectangle {
                width: parent.width * (stat.percent / 100)
                height: parent.height
                radius: height / 2
                color: stat.barColor

                Behavior on width {
                    NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
                }

                Behavior on color {
                    ColorAnimation { duration: 600; easing.type: Easing.OutQuint }
                }
            }
        }
    }
}
