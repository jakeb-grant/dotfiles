import Quickshell.Services.Pipewire
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
                return Qt.tint(Utils.Theme.subtleText, Qt.rgba(
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
        height: Utils.Theme.sliderHeight

        readonly property real trackHeight: Utils.Theme.sliderTrackHeight
        readonly property real thumbSize: Utils.Theme.sliderThumbSize
        readonly property real effectiveWidth: width - thumbSize
        readonly property bool dragging: sliderMouse.pressed

        property real displayVolume: Services.Audio.volume

        Connections {
            target: Services.Audio
            function onVolumeChanged() {
                if (!slider.dragging && !volResync.running)
                    slider.displayVolume = Services.Audio.volume;
            }
        }

        Timer {
            id: volResync
            interval: 800
            onTriggered: slider.displayVolume = Services.Audio.volume
        }

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

            // Fill — masked flowing gradient
            Item {
                width: parent.width * slider.displayVolume
                height: parent.height

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: volFillMask
                }

                Rectangle {
                    id: volFillMask
                    anchors.fill: parent
                    radius: parent.height / 2
                    visible: false
                    layer.enabled: true
                }

                // Muted fallback
                Rectangle {
                    anchors.fill: parent
                    radius: parent.height / 2
                    color: Utils.Theme.subtleText
                    visible: Services.Audio.muted
                }

                // Flowing gradient
                Rectangle {
                    visible: !Services.Audio.muted
                    width: 2000
                    height: parent.height
                    x: -(root._flowOffset * 1000)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.000; color: Utils.Theme.lavender }
                        GradientStop { position: 0.167; color: Utils.Theme.accent }
                        GradientStop { position: 0.333; color: Utils.Theme.sapphire }
                        GradientStop { position: 0.500; color: Utils.Theme.lavender }
                        GradientStop { position: 0.667; color: Utils.Theme.accent }
                        GradientStop { position: 0.833; color: Utils.Theme.sapphire }
                        GradientStop { position: 1.000; color: Utils.Theme.lavender }
                    }
                }

                Behavior on width {
                    enabled: !slider.dragging
                    NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }
        }

        // Thumb
        Rectangle {
            id: thumb

            x: slider.thumbSize / 2 + slider.effectiveWidth * slider.displayVolume - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: slider.thumbSize
            height: slider.thumbSize
            radius: width / 2
            color: sliderMouse.containsMouse || sliderMouse.pressed
                ? Utils.Theme.text : Utils.Theme.subtext0
            scale: sliderMouse.pressed ? 1.4 : sliderMouse.containsMouse ? 1.15 : 1

            Behavior on x {
                enabled: !slider.dragging
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: sliderMouse.pressed ? 80 : Utils.Theme.animDurationFast
                    easing.type: sliderMouse.pressed ? Easing.OutQuad : Easing.OutBack
                }
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
                slider.displayVolume = vol;
                if (Services.Audio.sink?.audio)
                    Services.Audio.sink.audio.volume = vol;
            }

            onPressed: (mouse) => {
                volumeFromX(mouse.x);
            }

            onPositionChanged: (mouse) => {
                if (pressed) volumeFromX(mouse.x);
            }

            onReleased: volResync.restart()
            onCanceled: volResync.restart()
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

    // ── Now Playing ──
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
        visible: Services.Players.hasPlayer
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingNormal
        visible: Services.Players.hasPlayer

        // Album art + track info
        RowLayout {
            Layout.fillWidth: true
            spacing: Utils.Theme.spacingNormal

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: Utils.Theme.listItemRadius
                color: Utils.Theme.surface0
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: Services.Players.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Utils.MaterialIcon {
                    anchors.centerIn: parent
                    text: "music_note"
                    font.pixelSize: Utils.Theme.headerIconSize
                    color: Utils.Theme.overlay0
                    visible: !albumArt.visible
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Utils.Theme.spacingTiny

                Text {
                    Layout.fillWidth: true
                    text: Services.Players.trackTitle || "Unknown"
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.listFontSize
                    font.bold: true
                    color: Utils.Theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: Services.Players.trackArtist || "\u2014"
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.fontSizeSmall
                    color: Utils.Theme.subtleText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // Seek bar
        Item {
            id: seekBar

            Layout.fillWidth: true
            height: 14

            readonly property real trackH: 4
            readonly property real thumbSize: 10
            readonly property real effectiveWidth: width - thumbSize
            readonly property bool dragging: seekMouse.pressed
            readonly property real ratio: Services.Players.length > 0
                ? Services.Players.livePosition / Services.Players.length : 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: seekBar.thumbSize / 2
                anchors.rightMargin: seekBar.thumbSize / 2
                height: seekBar.trackH
                radius: height / 2
                color: Utils.Theme.pillBg

                Item {
                    width: parent.width * seekBar.ratio
                    height: parent.height

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: seekFillMask
                    }

                    Rectangle {
                        id: seekFillMask
                        anchors.fill: parent
                        radius: parent.height / 2
                        visible: false
                        layer.enabled: true
                    }

                    Rectangle {
                        width: 2000
                        height: parent.height
                        x: -(root._flowOffset * 1000)

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.000; color: Utils.Theme.accent }
                            GradientStop { position: 0.167; color: Utils.Theme.mauve }
                            GradientStop { position: 0.333; color: Utils.Theme.lavender }
                            GradientStop { position: 0.500; color: Utils.Theme.accent }
                            GradientStop { position: 0.667; color: Utils.Theme.mauve }
                            GradientStop { position: 0.833; color: Utils.Theme.lavender }
                            GradientStop { position: 1.000; color: Utils.Theme.accent }
                        }
                    }

                    Behavior on width {
                        enabled: !seekBar.dragging
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }
            }

            Rectangle {
                x: seekBar.thumbSize / 2 + seekBar.effectiveWidth * seekBar.ratio - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: seekBar.thumbSize
                height: seekBar.thumbSize
                radius: width / 2
                color: seekMouse.containsMouse || seekMouse.pressed
                    ? Utils.Theme.text : Utils.Theme.subtext0
                visible: Services.Players.canSeek

                Behavior on x {
                    enabled: !seekBar.dragging
                    NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: seekMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Services.Players.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: Services.Players.canSeek && Services.Players.length > 0

                function seekFromX(mouseX: real): void {
                    const clamped = Math.max(seekBar.thumbSize / 2,
                        Math.min(mouseX, seekBar.width - seekBar.thumbSize / 2));
                    const pos = (clamped - seekBar.thumbSize / 2) / seekBar.effectiveWidth * Services.Players.length;
                    Services.Players.setPosition(pos);
                }

                onPressed: (mouse) => seekFromX(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) seekFromX(mouse.x); }
            }
        }

        // Time + transport controls
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root._formatTime(Services.Players.livePosition) + " / " + root._formatTime(Services.Players.length)
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeXSmall
                color: Utils.Theme.disabledText
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: Utils.Theme.spacingLarge

                TransportButton {
                    icon: "skip_previous"
                    enabled: Services.Players.canGoPrevious
                    onClicked: Services.Players.previous()
                }

                TransportButton {
                    icon: Services.Players.isPlaying ? "pause" : "play_arrow"
                    enabled: Services.Players.hasPlayer
                    alwaysActive: true
                    onClicked: Services.Players.togglePlaying()
                }

                TransportButton {
                    icon: "skip_next"
                    enabled: Services.Players.canGoNext
                    onClicked: Services.Players.next()
                }
            }
        }
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

                transform: Translate {
                    x: !sinkDelegate.isDefault && sinkMouse.containsMouse ? 4 : 0
                    Behavior on x { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutExpo } }
                }

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

    component TransportButton: Item {
        id: btn

        required property string icon
        property bool alwaysActive: false

        signal clicked()

        width: Utils.Theme.headerIconSize
        height: Utils.Theme.headerIconSize

        Utils.MaterialIcon {
            anchors.centerIn: parent
            text: btn.icon
            font.pixelSize: Utils.Theme.headerIconSize
            color: btn.enabled
                ? (btnMouse.containsMouse ? Utils.Theme.accent : Utils.Theme.text)
                : Utils.Theme.disabledText
            fill: 1
            scale: btnMouse.pressed ? 0.85 : btnMouse.containsMouse ? 1.1 : 1

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: btnMouse.pressed ? 50 : 250
                    easing.type: btnMouse.pressed ? Easing.OutQuad : Easing.OutBack
                }
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.clicked()
        }
    }

    function _formatTime(seconds: real): string {
        if (seconds <= 0) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
