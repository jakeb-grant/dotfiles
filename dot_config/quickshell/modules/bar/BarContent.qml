import qs.modules.bar.components
import Quickshell
import Quickshell.Services.SystemTray
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

    GridLayout {
        anchors.fill: parent
        flow: Utils.Theme.isSide ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: Utils.Theme.isTop ? -1 : 1
        rows: Utils.Theme.isSide ? -1 : 1
        columnSpacing: Utils.Theme.isTop ? Utils.Theme.spacingSmall : 0
        rowSpacing: Utils.Theme.isSide ? Utils.Theme.spacingSmall : 0

        Spacer { size: Utils.Theme.spacingSmall }

        BarItem {
            step: 0
            popout: "system"

            Text {
                anchors.centerIn: parent
                text: "\uf303"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtleText
            }
        }

        BarItem {
            step: 1

            Workspaces {
                screen: root.screen
                entranceReady: root._animStep >= 1
            }
        }

        Spacer { fill: true }

        BarItem {
            step: 2
            // Mirrors TrayOverflow's own condition — an invisible child can't
            // drive parent visibility (visible reads as effective visibility,
            // which would latch false once hidden).
            visible: SystemTray.items.values.length > 0

            TrayOverflow {
                screen: root.screen
            }
        }

        Spacer { size: Utils.Theme.spacingNormal }

        BarItem {
            id: clockItem
            step: 3
            popout: "calendar"
            implicitWidth: Utils.Theme.isSide ? Utils.Theme.barInnerWidth : clockRow.implicitWidth
            implicitHeight: Utils.Theme.isSide ? clockCol.implicitHeight : clockRow.implicitHeight

            Column {
                id: clockCol
                anchors.centerIn: parent
                visible: Utils.Theme.isSide
                spacing: Utils.Theme.spacingTiny

                Utils.MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "calendar_today"
                    // Hover affordance — sanctioned exception to the bar's
                    // no-hover-decoration rule (see DEVGUIDE): the glyph fills
                    // and warms to accent, hinting the calendar popout.
                    fill: clockItem.hovered ? 1 : 0
                    font.pixelSize: Utils.Theme.iconSize
                    color: clockItem.hovered ? Utils.Theme.accent : Utils.Theme.subtleText
                    Behavior on color { ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic } }
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

            Row {
                id: clockRow
                anchors.centerIn: parent
                visible: Utils.Theme.isTop
                spacing: Utils.Theme.spacingTiny

                Utils.MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "calendar_today"
                    // Same hover affordance as the side-bar glyph above.
                    fill: clockItem.hovered ? 1 : 0
                    font.pixelSize: Utils.Theme.iconSize
                    color: clockItem.hovered ? Utils.Theme.accent : Utils.Theme.subtleText
                    Behavior on color { ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic } }
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
        }

        Spacer { size: Utils.Theme.spacingSmall }

        BarItem {
            step: 4

            StatusIcons {
                screen: root.screen
            }
        }

        Spacer { size: Utils.Theme.spacingSmall }

        BarItem {
            step: 5
            popout: "power"

            Utils.MaterialIcon {
                anchors.centerIn: parent
                text: "power_settings_new"
                fill: 1
                font.pixelSize: Utils.Theme.iconSize + 4
                color: Utils.Theme.red
            }
        }

        Spacer { size: Utils.Theme.spacingNormal }
    }

    // One bar entry: entrance step (drop-in shift + fade), orientation-aware
    // alignment, and optional hover-popout wiring. Sizes to its first child;
    // override implicitWidth/Height for multi-child content.
    component BarItem: Item {
        id: barItem

        required property int step
        // Popout to open on hover; "" for items that manage their own hover
        property string popout: ""
        // Hover state for content that wants an affordance (only the clock —
        // the sanctioned exception to the no-hover-decoration rule).
        readonly property bool hovered: popoutMouse.containsMouse
        default property alias content: slot.data

        Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
        implicitWidth: slot.children[0]?.implicitWidth ?? 0
        implicitHeight: slot.children[0]?.implicitHeight ?? 0

        property real _shift: root._animStep >= step ? 0 : 12
        Behavior on _shift { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        opacity: root._animStep >= step ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic } }
        transform: Translate {
            x: Utils.Theme.isTop ? barItem._shift : 0
            y: Utils.Theme.isSide ? barItem._shift : 0
        }

        Item {
            id: slot
            anchors.fill: parent
        }

        MouseArea {
            id: popoutMouse
            anchors.fill: parent
            visible: barItem.popout !== ""
            hoverEnabled: true
            onEntered: Services.Popout.showFrom(barItem, barItem.popout, root.screen)
            onExited: Services.Popout.barItemExited()
        }
    }

    // Layout gap that follows the bar's parallel axis.
    component Spacer: Item {
        property real size: 0
        property bool fill: false

        Layout.preferredWidth: Utils.Theme.isTop ? size : 0
        Layout.preferredHeight: Utils.Theme.isSide ? size : 0
        Layout.fillWidth: Utils.Theme.isTop && fill
        Layout.fillHeight: Utils.Theme.isSide && fill
    }
}
