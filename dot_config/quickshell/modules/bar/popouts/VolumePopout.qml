import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Audio.icon
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

    FlowSlider {
        id: slider

        // Local display value decoupled from the service while dragging, with
        // a resync grace period so late Pipewire echoes don't snap the thumb.
        property real displayVolume: Services.Audio.volume

        Layout.fillWidth: true
        value: displayVolume
        flowColors: [Utils.Theme.lavender, Utils.Theme.accent, Utils.Theme.sapphire]
        flatFill: Services.Audio.muted

        onMoved: (newValue) => {
            displayVolume = newValue;
            Services.Audio.setVolume(newValue);
        }
        onReleased: volResync.restart()

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
    Separator {
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
                    text: Services.Players.trackArtist || "—"
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.fontSizeSmall
                    color: Utils.Theme.subtleText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // Seek bar
        FlowSlider {
            Layout.fillWidth: true
            implicitHeight: 14
            trackHeight: 4
            thumbSize: 10
            thumbBounce: false
            thumbVisible: Services.Players.canSeek
            enabled: Services.Players.canSeek && Services.Players.length > 0
            value: Services.Players.length > 0
                ? Services.Players.livePosition / Services.Players.length : 0
            flowColors: [Utils.Theme.accent, Utils.Theme.mauve, Utils.Theme.lavender]

            onMoved: (newValue) => Services.Players.setPosition(newValue * Services.Players.length)
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

                IconButton {
                    text: "skip_previous"
                    font.pixelSize: Utils.Theme.headerIconSize
                    fill: 1
                    bounce: true
                    hitPadding: 4
                    baseColor: Utils.Theme.text
                    hoverColor: Utils.Theme.accent
                    enabled: Services.Players.canGoPrevious
                    onClicked: Services.Players.previous()
                }

                IconButton {
                    text: Services.Players.isPlaying ? "pause" : "play_arrow"
                    font.pixelSize: Utils.Theme.headerIconSize
                    fill: 1
                    bounce: true
                    hitPadding: 4
                    baseColor: Utils.Theme.text
                    hoverColor: Utils.Theme.accent
                    enabled: Services.Players.hasPlayer
                    onClicked: Services.Players.togglePlaying()
                }

                IconButton {
                    text: "skip_next"
                    font.pixelSize: Utils.Theme.headerIconSize
                    fill: 1
                    bounce: true
                    hitPadding: 4
                    baseColor: Utils.Theme.text
                    hoverColor: Utils.Theme.accent
                    enabled: Services.Players.canGoNext
                    onClicked: Services.Players.next()
                }
            }
        }
    }

    Separator {
        visible: sinkRepeater.count > 0
    }

    SectionLabel {
        text: "Output"
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

            delegate: ListRow {
                id: sinkDelegate

                required property var modelData

                readonly property bool isDefault: modelData === Pipewire.defaultAudioSink

                width: parent?.width ?? 0
                interactive: !isDefault
                onClicked: Services.Audio.setSink(modelData)

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
        }
    }

    Separator {
        visible: sourceRepeater.count > 0
    }

    SectionLabel {
        text: "Input"
        visible: sourceRepeater.count > 0
    }

    Column {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingTiny
        visible: sourceRepeater.count > 0

        Repeater {
            id: sourceRepeater
            model: Services.Audio.sources

            delegate: ListRow {
                id: sourceDelegate

                required property var modelData

                readonly property bool isDefault: modelData === Pipewire.defaultAudioSource

                width: parent?.width ?? 0
                interactive: !isDefault
                onClicked: Services.Audio.setSource(modelData)

                // Device type icon
                Utils.MaterialIcon {
                    text: {
                        const desc = (sourceDelegate.modelData.description ?? "").toLowerCase();
                        if (desc.includes("headphone") || desc.includes("headset")) return "headset_mic";
                        if (desc.includes("webcam") || desc.includes("camera")) return "videocam";
                        return "mic";
                    }
                    font.pixelSize: Utils.Theme.iconSizeSmall
                    color: sourceDelegate.isDefault ? Utils.Theme.accent : Utils.Theme.subtleText
                    Layout.alignment: Qt.AlignVCenter
                }

                // Device name
                Text {
                    text: sourceDelegate.modelData.description || sourceDelegate.modelData.nickname || sourceDelegate.modelData.name || "Unknown"
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.listFontSize
                    color: Utils.Theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Active check
                Utils.MaterialIcon {
                    visible: sourceDelegate.isDefault
                    text: "check"
                    font.pixelSize: Utils.Theme.headerFontSize
                    color: Utils.Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    function _formatTime(seconds: real): string {
        if (seconds <= 0) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
