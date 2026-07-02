import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

// Transient feedback island for volume/brightness/media keys. Positioned by
// Drawers; visibility is driven entirely by Services.Osd. Carries no input
// handling — it never joins the window's input mask, so clicks pass through.
Rectangle {
    id: root

    readonly property string mode: Services.Osd.mode
    readonly property bool isVolume: mode === "volume"
    readonly property bool isMedia: mode === "media"
    readonly property bool showsMuted: isVolume && Services.Audio.muted
    readonly property real fillValue: isVolume
        ? Services.Audio.volumePercent / 100
        : Services.Brightness.percent / 100

    implicitWidth: 300
    implicitHeight: 52
    radius: Utils.Theme.islandRounding
    color: Utils.Theme.mantleAlpha

    opacity: Services.Osd.visible ? 1 : 0
    visible: opacity > 0
    scale: Services.Osd.visible ? 1 : 0.92

    Behavior on opacity {
        NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
    }

    layer.enabled: visible
    layer.smooth: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Utils.Theme.islandShadowColor
        shadowOpacity: Utils.Theme.islandShadowOpacity
        blurMax: Utils.Theme.islandShadowBlur
        shadowVerticalOffset: Utils.Theme.islandShadowY
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Utils.Theme.spacingLarge + Utils.Theme.spacingSmall
        anchors.rightMargin: Utils.Theme.spacingLarge + Utils.Theme.spacingSmall
        spacing: Utils.Theme.spacingLarge

        Utils.MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: {
                if (root.isMedia) return Services.Players.isPlaying ? "play_arrow" : "pause";
                if (root.isVolume) return Services.Audio.icon;
                return Services.Brightness.icon;
            }
            fill: 1
            font.pixelSize: Utils.Theme.headerIconSize
            color: root.showsMuted ? Utils.Theme.subtleText : Utils.Theme.accent
        }

        // Volume/brightness: fill bar + fixed-width label
        Item {
            visible: !root.isMedia
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: Utils.Theme.sliderTrackHeight

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Utils.Theme.surface0
            }
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, root.fillValue))
                height: parent.height
                radius: height / 2
                color: root.showsMuted ? Utils.Theme.subtleText : Utils.Theme.accent

                Behavior on width {
                    NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            visible: !root.isMedia
            Layout.alignment: Qt.AlignVCenter
            // Fixed width so the bar doesn't wiggle as "5%" grows to "100%"
            Layout.preferredWidth: 48
            horizontalAlignment: Text.AlignRight
            text: root.showsMuted
                ? "Muted"
                : (root.isVolume ? Services.Audio.volumePercent : Services.Brightness.percent) + "%"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: root.showsMuted ? Utils.Theme.subtleText : Utils.Theme.text
        }

        // Media: track info
        ColumnLayout {
            visible: root.isMedia
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: Services.Players.hasPlayer
                    ? (Services.Players.trackTitle || "Unknown track")
                    : "Nothing playing"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                font.bold: true
                color: Utils.Theme.text
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: Services.Players.hasPlayer ? Services.Players.trackArtist : ""
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeXSmall
                color: Utils.Theme.subtleText
                elide: Text.ElideRight
            }
        }
    }
}
