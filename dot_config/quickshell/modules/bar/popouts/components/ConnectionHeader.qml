import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

// Wifi/Bluetooth-style popout header: leading icon, crossfade between a
// connected two-line block (title + subtitle) and a disconnected label,
// and a link_off disconnect button that fades in while connected.
RowLayout {
    id: root

    property bool connected
    property string title
    property string subtitle
    property string disconnectedText
    // Leading icon (loaded first so it can be a MaterialIcon or nerd-font Text)
    property Component icon

    signal disconnectClicked()

    spacing: Utils.Theme.spacingNormal

    Loader {
        sourceComponent: root.icon
        Layout.alignment: Qt.AlignVCenter
    }

    // Connected: two-line column (title + details)
    ColumnLayout {
        opacity: (root.connected && root.title !== "") ? 1 : 0
        visible: opacity > 0.001
        spacing: Utils.Theme.spacingTiny
        Layout.fillWidth: true

        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }

        Text {
            text: root.title
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.headerFontSize
            font.bold: true
            color: Utils.Theme.text
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.subtitle
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtext0
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // Disconnected: single centered label
    Text {
        opacity: (!root.connected || root.title === "") ? 1 : 0
        visible: opacity > 0.001
        text: root.disconnectedText
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.headerFontSize
        font.bold: true
        color: Utils.Theme.text
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }
    }

    // Disconnect button (only when connected)
    IconButton {
        visible: opacity > 0
        opacity: root.connected ? 1 : 0
        text: "link_off"
        font.pixelSize: Utils.Theme.headerActionIconSize
        hoverColor: Utils.Theme.red
        onClicked: root.disconnectClicked()

        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }
    }
}
