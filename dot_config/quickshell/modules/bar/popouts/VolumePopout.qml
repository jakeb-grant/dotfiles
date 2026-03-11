import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal
    implicitWidth: 220

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
            font.pixelSize: 24
            color: Services.Audio.muted ? Utils.Theme.overlay0 : Utils.Theme.blue

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
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
            font.pixelSize: 18
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
            color: Utils.Theme.surface0

            // Fill
            Rectangle {
                width: parent.width * Services.Audio.volume
                height: parent.height
                radius: height / 2
                color: Services.Audio.muted ? Utils.Theme.overlay0 : sliderColor

                readonly property color sliderColor: {
                    const v = Services.Audio.volumePercent;
                    if (v <= 35) return Utils.Theme.lavender;
                    if (v <= 60) return Utils.Theme.blue;
                    if (v <= 85) return Utils.Theme.teal;
                    return Utils.Theme.green;
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
        color: Utils.Theme.overlay0
    }
}
