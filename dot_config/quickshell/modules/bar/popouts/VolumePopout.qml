import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: Utils.Theme.popoutWidth
        implicitHeight: 0
    }

    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: {
                const v = Services.Audio.volumePercent;
                if (Services.Audio.muted) return "volume_off";
                if (v === 0) return "volume_mute";
                if (v <= 25) return "volume_down";
                return "volume_up";
            }
            fill: Services.Audio.muted ? 0 : 1
            font.pixelSize: Utils.Theme.headerIconSize
            color: {
                if (Services.Audio.muted || Services.Audio.volumePercent === 0)
                    return Utils.Theme.subtleText;
                const t = Math.min(1, Services.Audio.volumePercent / 100);
                return Qt.tint(Utils.Theme.lavender, Qt.rgba(
                    Utils.Theme.accent.r, Utils.Theme.accent.g, Utils.Theme.accent.b, t));
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Audio.toggleMute()
            }
        }

        Text {
            text: Services.Audio.muted ? "Muted" : Services.Audio.volumePercent + "%"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
            Layout.fillWidth: true
        }
    }

    // Interactive volume slider
    Item {
        id: slider

        Layout.fillWidth: true
        height: 24

        readonly property real trackHeight: 6
        readonly property real thumbSize: 16
        readonly property real effectiveWidth: width - thumbSize
        readonly property bool dragging: sliderMouse.pressed

        // Track background
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: slider.thumbSize / 2
            anchors.rightMargin: slider.thumbSize / 2
            height: slider.trackHeight
            radius: height / 2
            color: Utils.Theme.pillBg

            // Fill
            Rectangle {
                width: parent.width * Services.Audio.volume
                height: parent.height
                radius: height / 2
                color: Services.Audio.muted ? Utils.Theme.subtleText : sliderColor

                readonly property color sliderColor: {
                    const t = Math.min(1, Services.Audio.volumePercent / 100);
                    return Qt.tint(Utils.Theme.lavender, Qt.rgba(
                        Utils.Theme.accent.r, Utils.Theme.accent.g, Utils.Theme.accent.b, t));
                }

                Behavior on width {
                    enabled: !slider.dragging
                    NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }
        }

        // Thumb
        Rectangle {
            id: thumb

            x: slider.thumbSize / 2 + slider.effectiveWidth * Services.Audio.volume - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: slider.thumbSize
            height: slider.thumbSize
            radius: width / 2
            color: sliderMouse.containsMouse || sliderMouse.pressed
                ? Utils.Theme.text : Utils.Theme.subtext0
            scale: sliderMouse.pressed ? 1.2 : sliderMouse.containsMouse ? 1.1 : 1

            Behavior on x {
                enabled: !slider.dragging
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        // Drag/click area covers full slider
        MouseArea {
            id: sliderMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function volumeFromX(mouseX: real): void {
                const clamped = Math.max(slider.thumbSize / 2,
                    Math.min(mouseX, slider.width - slider.thumbSize / 2));
                const vol = (clamped - slider.thumbSize / 2) / slider.effectiveWidth;
                if (Services.Audio.sink?.audio)
                    Services.Audio.sink.audio.volume = vol;
            }

            onPressed: (mouse) => {
                volumeFromX(mouse.x);
            }

            onPositionChanged: (mouse) => {
                if (pressed) volumeFromX(mouse.x);
            }
        }
    }

    // Mute hint
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Services.Audio.muted ? "click icon to unmute" : "scroll or drag to adjust"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtleText
    }

    // --- Separator ---
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
        visible: sinkRepeater.count > 0
    }

    // --- Section header: "Output" ---
    Text {
        text: "Output"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        font.weight: Font.Medium
        color: Utils.Theme.subtext0
        visible: sinkRepeater.count > 0
    }

    // --- Device list ---
    Column {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingTiny
        visible: sinkRepeater.count > 0

        Repeater {
            id: sinkRepeater
            model: Services.Audio.sinks

            delegate: Rectangle {
                id: sinkDelegate

                required property var modelData

                readonly property bool isDefault: modelData === Pipewire.defaultAudioSink

                width: parent?.width ?? 0
                height: Utils.Theme.listItemHeight
                radius: Utils.Theme.listItemRadius
                color: "transparent"

                // Hover background
                Rectangle {
                    anchors.fill: parent
                    radius: Utils.Theme.listItemRadius
                    color: Utils.Theme.hoverBg
                    opacity: !sinkDelegate.isDefault && sinkMouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Utils.Theme.listItemMargin
                    anchors.rightMargin: Utils.Theme.listItemMargin
                    spacing: Utils.Theme.spacingNormal

                    // Device type icon
                    Utils.MaterialIcon {
                        text: {
                            const desc = (sinkDelegate.modelData.description ?? "").toLowerCase();
                            if (desc.includes("headphone") || desc.includes("headset")) return "headphones";
                            if (desc.includes("hdmi") || desc.includes("monitor") || desc.includes("display")) return "monitor";
                            if (desc.includes("bluetooth") || desc.includes("a2dp")) return "bluetooth";
                            return "volume_up";
                        }
                        font.pixelSize: Utils.Theme.iconSizeSmall
                        color: sinkDelegate.isDefault ? Utils.Theme.accent : Utils.Theme.subtleText
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Device name
                    Text {
                        text: sinkDelegate.modelData.description || sinkDelegate.modelData.nickname || sinkDelegate.modelData.name || "Unknown"
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.listFontSize
                        color: Utils.Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Active check
                    Utils.MaterialIcon {
                        visible: sinkDelegate.isDefault
                        text: "check"
                        font.pixelSize: Utils.Theme.headerFontSize
                        color: Utils.Theme.accent
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: sinkMouse
                    anchors.fill: parent
                    hoverEnabled: !sinkDelegate.isDefault
                    cursorShape: sinkDelegate.isDefault ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !sinkDelegate.isDefault
                    onClicked: Services.Audio.setSink(sinkDelegate.modelData)
                }
            }
        }
    }
}
