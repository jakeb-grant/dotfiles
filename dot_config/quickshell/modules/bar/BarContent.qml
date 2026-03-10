import qs.modules.bar.components
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    required property ShellScreen screen

    spacing: Utils.Theme.spacingNormal

    // Top padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

    // Arch logo
    Item {
        id: archLogo

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: archText.implicitWidth
        implicitHeight: archText.implicitHeight

        Text {
            id: archText
            anchors.centerIn: parent
            text: "\uf303"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.blue
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                const globalPos = archLogo.mapToGlobal(0, archLogo.height / 2);
                Services.Popout.show("system", globalPos.y, root.screen);
            }
            onExited: {
                Services.Popout.barItemHovered = false;
                Services.Popout.requestClose();
            }
        }
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
        screen: root.screen
    }

    ClockWidget {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // Bottom padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }
}
