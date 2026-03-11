import qs.modules.bar.components
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    required property ShellScreen screen

    spacing: Utils.Theme.spacingSmall

    // Top padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

    // ── Arch Logo (standalone) ──
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

    // ── Workspaces (pill + sliding indicator) ──
    Workspaces {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // ── Spacer ──
    Item { Layout.fillHeight: true }

    // ── System Tray Icons ──
    TrayOverflow {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // ── Gap ──
    Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

    // ── Calendar + Clock (no pill, own group) ──

    // Calendar
    Item {
        id: calendarItem

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: calendarIcon.implicitWidth
        implicitHeight: calendarIcon.implicitHeight

        Utils.MaterialIcon {
            id: calendarIcon
            anchors.centerIn: parent
            text: "calendar_today"
            fill: 0
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.overlay1
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                const globalPos = calendarItem.mapToGlobal(0, calendarItem.height / 2);
                Services.Popout.show("calendar", globalPos.y, root.screen);
            }
            onExited: {
                Services.Popout.barItemHovered = false;
                Services.Popout.requestClose();
            }
        }
    }

    // Clock
    ClockWidget {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // ── Gap ──
    Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

    // ── System Icons (pill grouping: volume, wifi, bluetooth, battery) ──
    StatusIcons {
        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // ── Gap ──
    Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

    // ── Power (prominent, standalone) ──
    Item {
        id: powerItem

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: powerIcon.implicitWidth
        implicitHeight: powerIcon.implicitHeight

        Utils.MaterialIcon {
            id: powerIcon
            anchors.centerIn: parent
            text: "power_settings_new"
            fill: 1
            font.pixelSize: Utils.Theme.iconSize + 4
            color: Utils.Theme.red
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                const globalPos = powerItem.mapToGlobal(0, powerItem.height / 2);
                Services.Popout.show("power", globalPos.y, root.screen);
            }
            onExited: {
                Services.Popout.barItemHovered = false;
                Services.Popout.requestClose();
            }
        }
    }

    // Bottom padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }
}
