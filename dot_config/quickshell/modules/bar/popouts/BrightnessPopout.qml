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
                const p = Services.Brightness.percent;
                if (p <= 14) return "brightness_1";
                if (p <= 28) return "brightness_2";
                if (p <= 42) return "brightness_3";
                if (p <= 56) return "brightness_4";
                if (p <= 70) return "brightness_5";
                if (p <= 85) return "brightness_6";
                return "brightness_7";
            }
            fill: 1
            font.pixelSize: Utils.Theme.headerIconSize
            color: {
                const t = Math.min(1, Services.Brightness.percent / 100);
                if (t <= 0.5) {
                    const s = t / 0.5;
                    return Qt.tint(Utils.Theme.lavender, Qt.rgba(
                        Utils.Theme.blue.r, Utils.Theme.blue.g, Utils.Theme.blue.b, s));
                }
                const s = (t - 0.5) / 0.5;
                return Qt.tint(Utils.Theme.blue, Qt.rgba(
                    Utils.Theme.yellow.r, Utils.Theme.yellow.g, Utils.Theme.yellow.b, s));
            }
        }

        Text {
            text: Services.Brightness.percent + "%"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
            Layout.fillWidth: true
        }
    }

    // Interactive brightness slider
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
                width: parent.width * Services.Brightness.brightness
                height: parent.height
                radius: height / 2
                color: sliderColor

                readonly property color sliderColor: {
                    const t = Math.min(1, Services.Brightness.percent / 100);
                    if (t <= 0.5) {
                        const s = t / 0.5;
                        return Qt.tint(Utils.Theme.lavender, Qt.rgba(
                            Utils.Theme.blue.r, Utils.Theme.blue.g, Utils.Theme.blue.b, s));
                    }
                    const s = (t - 0.5) / 0.5;
                    return Qt.tint(Utils.Theme.blue, Qt.rgba(
                        Utils.Theme.yellow.r, Utils.Theme.yellow.g, Utils.Theme.yellow.b, s));
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

            x: slider.thumbSize / 2 + slider.effectiveWidth * Services.Brightness.brightness - width / 2
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

        // Drag/click area
        MouseArea {
            id: sliderMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function brightnessFromX(mouseX: real): void {
                const clamped = Math.max(slider.thumbSize / 2,
                    Math.min(mouseX, slider.width - slider.thumbSize / 2));
                const pct = Math.round((clamped - slider.thumbSize / 2) / slider.effectiveWidth * 100);
                Services.Brightness.setBrightness(pct);
            }

            onPressed: (mouse) => {
                brightnessFromX(mouse.x);
            }

            onPositionChanged: (mouse) => {
                if (pressed) brightnessFromX(mouse.x);
            }
        }
    }

    // Hint
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "scroll or drag to adjust"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtleText
    }
}
