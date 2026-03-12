import qs.modules.bar.components
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    required property ShellScreen screen

    // ── Startup entrance animation ──
    // _animStep increments every 50ms; each item fades in when step >= its index
    property int _animStep: -1

    Timer {
        id: entranceTimer
        interval: 70
        repeat: true
        running: true
        onTriggered: {
            root._animStep++;
            if (root._animStep >= 6)
                entranceTimer.stop();
        }
    }

    spacing: Utils.Theme.spacingSmall

    // Top padding
    Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

    // ── Arch Logo (standalone) — step 0 ──
    Item {
        id: archLogo

        property real _yShift: root._animStep >= 0 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 0 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: archLogo._yShift }

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: archText.implicitWidth
        implicitHeight: archText.implicitHeight

        Text {
            id: archText
            anchors.centerIn: parent
            text: "\uf303"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtleText
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

    // ── Theme Selector — step 1 ──
    Item {
        id: themeItem

        property real _yShift: root._animStep >= 1 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 1 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: themeItem._yShift }

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: themeIcon.implicitWidth
        implicitHeight: themeIcon.implicitHeight

        Utils.MaterialIcon {
            id: themeIcon
            anchors.centerIn: parent
            text: "palette"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtleText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                const globalPos = themeItem.mapToGlobal(0, themeItem.height / 2);
                Services.Popout.show("theme", globalPos.y, root.screen);
            }
            onExited: {
                Services.Popout.barItemHovered = false;
                Services.Popout.requestClose();
            }
        }
    }

    // ── Workspaces (pill + sliding indicator) — step 2 ──
    Workspaces {
        id: workspaces

        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
        entranceReady: root._animStep >= 2

        property real _yShift: root._animStep >= 2 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 2 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: workspaces._yShift }
    }

    // ── Spacer ──
    Item { Layout.fillHeight: true }

    // ── System Tray Icons — step 3 ──
    TrayOverflow {
        id: trayOverflow

        property real _yShift: root._animStep >= 3 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 3 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: trayOverflow._yShift }

        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // ── Gap ──
    Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

    // ── Calendar + Clock (single hover group) — step 4 ──
    Item {
        id: calendarClockGroup

        property real _yShift: root._animStep >= 4 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 4 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: calendarClockGroup._yShift }

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Utils.Theme.barInnerWidth
        implicitHeight: calendarClockCol.implicitHeight

        Column {
            id: calendarClockCol
            anchors.centerIn: parent
            spacing: Utils.Theme.spacingTiny

            Utils.MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "calendar_today"
                fill: 0
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtleText
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Services.Clock.hours
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.headerFontSize
                font.bold: true
                color: Utils.Theme.text
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Services.Clock.minutes
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.headerFontSize
                font.bold: true
                color: Utils.Theme.subtext1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Services.Clock.ampm
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeXSmall
                font.weight: Font.Medium
                font.letterSpacing: 2
                color: Utils.Theme.disabledText
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                const globalPos = calendarClockGroup.mapToGlobal(0, calendarClockGroup.height / 2);
                Services.Popout.show("calendar", globalPos.y, root.screen);
            }
            onExited: {
                Services.Popout.barItemHovered = false;
                Services.Popout.requestClose();
            }
        }
    }

    // ── Gap ──
    Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

    // ── System Icons (pill grouping) — step 5 ──
    StatusIcons {
        id: statusIcons

        property real _yShift: root._animStep >= 5 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 5 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: statusIcons._yShift }

        Layout.alignment: Qt.AlignHCenter
        screen: root.screen
    }

    // ── Gap ──
    Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

    // ── Power (prominent, standalone) — step 6 ──
    Item {
        id: powerItem

        property real _yShift: root._animStep >= 6 ? 0 : 12
        Behavior on _yShift {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        opacity: root._animStep >= 6 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: powerItem._yShift }

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
