import qs.modules.bar.components
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

ColumnLayout {
    id: root

    required property ShellScreen screen

    spacing: Utils.Theme.spacingNormal

    // Top padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

    // Arch logo
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "\uf303"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.iconSize
        color: Utils.Theme.blue
    }

    Workspaces {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // Top spacer
    Item { Layout.fillHeight: true }

    ActiveWindow {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.maximumHeight: 200
    }

    // Bottom spacer
    Item { Layout.fillHeight: true }

    Tray {
        Layout.alignment: Qt.AlignHCenter
    }

    StatusIcons {
        Layout.alignment: Qt.AlignHCenter
    }

    ClockWidget {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // Bottom padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }
}
