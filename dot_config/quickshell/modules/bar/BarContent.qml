import qs.modules.bar.components
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    required property ShellScreen screen

    // ── Startup entrance animation ──
    property int _animStep: -1

    Timer {
        id: entranceTimer
        interval: 70
        repeat: true
        running: true
        onTriggered: {
            root._animStep++;
            if (root._animStep >= 5)
                entranceTimer.stop();
        }
    }

    function _showPopout(item: Item, name: string) {
        const gp = Utils.Theme.isSide
            ? item.mapToGlobal(0, item.height / 2)
            : item.mapToGlobal(item.width / 2, 0);
        Services.Popout.show(name,
            Utils.Theme.isTop ? gp.x : 0,
            Utils.Theme.isSide ? gp.y : 0,
            root.screen);
    }

    // ── Side mode: ColumnLayout ──
    ColumnLayout {
        id: sideLayout
        anchors.fill: parent
        visible: Utils.Theme.isSide
        spacing: Utils.Theme.spacingSmall

        Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

        Item {
            id: archLogoSide
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: archTextSide.implicitWidth
            implicitHeight: archTextSide.implicitHeight
            property real _shift: root._animStep >= 0 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { y: archLogoSide._shift }

            Text {
                id: archTextSide
                anchors.centerIn: parent
                text: "\uf303"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtleText
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root._showPopout(archLogoSide, "system")
                onExited: { Services.Popout.barItemHovered = false; Services.Popout.requestClose(); }
            }
        }

        Workspaces {
            id: workspacesSide
            Layout.alignment: Qt.AlignHCenter
            screen: root.screen
            entranceReady: root._animStep >= 1
            property real _shift: root._animStep >= 1 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { y: workspacesSide._shift }
        }

        Item { Layout.fillHeight: true }

        TrayOverflow {
            id: traySide
            Layout.alignment: Qt.AlignHCenter
            screen: root.screen
            property real _shift: root._animStep >= 2 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 2 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { y: traySide._shift }
        }

        Item { Layout.preferredHeight: Utils.Theme.spacingNormal }

        Item {
            id: clockSide
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Utils.Theme.barInnerWidth
            implicitHeight: calendarClockCol.implicitHeight
            property real _shift: root._animStep >= 3 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 3 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { y: clockSide._shift }

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
                onEntered: root._showPopout(clockSide, "calendar")
                onExited: { Services.Popout.barItemHovered = false; Services.Popout.requestClose(); }
            }
        }

        Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

        StatusIcons {
            id: statusSide
            Layout.alignment: Qt.AlignHCenter
            screen: root.screen
            property real _shift: root._animStep >= 4 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 4 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { y: statusSide._shift }
        }

        Item { Layout.preferredHeight: Utils.Theme.spacingSmall }

        Item {
            id: powerSide
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: powerIconSide.implicitWidth
            implicitHeight: powerIconSide.implicitHeight
            property real _shift: root._animStep >= 5 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 5 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { y: powerSide._shift }

            Utils.MaterialIcon {
                id: powerIconSide
                anchors.centerIn: parent
                text: "power_settings_new"
                fill: 1
                font.pixelSize: Utils.Theme.iconSize + 4
                color: Utils.Theme.red
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root._showPopout(powerSide, "power")
                onExited: { Services.Popout.barItemHovered = false; Services.Popout.requestClose(); }
            }
        }

        Item { Layout.preferredHeight: Utils.Theme.spacingNormal }
    }

    // ── Top mode: RowLayout ──
    RowLayout {
        id: topLayout
        anchors.fill: parent
        visible: Utils.Theme.isTop
        spacing: Utils.Theme.spacingSmall

        Item { Layout.preferredWidth: Utils.Theme.spacingSmall }

        Item {
            id: archLogoTop
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: archTextTop.implicitWidth
            implicitHeight: archTextTop.implicitHeight
            property real _shift: root._animStep >= 0 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { x: archLogoTop._shift }

            Text {
                id: archTextTop
                anchors.centerIn: parent
                text: "\uf303"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtleText
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root._showPopout(archLogoTop, "system")
                onExited: { Services.Popout.barItemHovered = false; Services.Popout.requestClose(); }
            }
        }

        Workspaces {
            id: workspacesTop
            Layout.alignment: Qt.AlignVCenter
            screen: root.screen
            entranceReady: root._animStep >= 1
            property real _shift: root._animStep >= 1 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { x: workspacesTop._shift }
        }

        Item { Layout.fillWidth: true }

        TrayOverflow {
            id: trayTop
            Layout.alignment: Qt.AlignVCenter
            screen: root.screen
            property real _shift: root._animStep >= 2 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 2 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { x: trayTop._shift }
        }

        Item { Layout.preferredWidth: Utils.Theme.spacingNormal }

        Item {
            id: clockTop
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: clockTopRow.implicitWidth
            implicitHeight: clockTopRow.implicitHeight
            property real _shift: root._animStep >= 3 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 3 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { x: clockTop._shift }

            Row {
                id: clockTopRow
                anchors.centerIn: parent
                spacing: Utils.Theme.spacingTiny

                Utils.MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "calendar_today"
                    fill: 0
                    font.pixelSize: Utils.Theme.iconSize
                    color: Utils.Theme.subtleText
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Clock.hours + ":" + Services.Clock.minutes
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.headerFontSize
                    font.bold: true
                    color: Utils.Theme.text
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
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
                onEntered: root._showPopout(clockTop, "calendar")
                onExited: { Services.Popout.barItemHovered = false; Services.Popout.requestClose(); }
            }
        }

        Item { Layout.preferredWidth: Utils.Theme.spacingSmall }

        StatusIcons {
            id: statusTop
            Layout.alignment: Qt.AlignVCenter
            screen: root.screen
            property real _shift: root._animStep >= 4 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 4 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { x: statusTop._shift }
        }

        Item { Layout.preferredWidth: Utils.Theme.spacingSmall }

        Item {
            id: powerTop
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: powerIconTop.implicitWidth
            implicitHeight: powerIconTop.implicitHeight
            property real _shift: root._animStep >= 5 ? 0 : 12
            Behavior on _shift { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            opacity: root._animStep >= 5 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
            transform: Translate { x: powerTop._shift }

            Utils.MaterialIcon {
                id: powerIconTop
                anchors.centerIn: parent
                text: "power_settings_new"
                fill: 1
                font.pixelSize: Utils.Theme.iconSize + 4
                color: Utils.Theme.red
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root._showPopout(powerTop, "power")
                onExited: { Services.Popout.barItemHovered = false; Services.Popout.requestClose(); }
            }
        }

        Item { Layout.preferredWidth: Utils.Theme.spacingNormal }
    }
}
