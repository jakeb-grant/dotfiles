pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: Utils.Theme.isSide ? Utils.Theme.barInnerWidth : layout.implicitWidth
    implicitHeight: Utils.Theme.isTop ? Utils.Theme.barInnerWidth : layout.implicitHeight
    visible: layout.visibleChildren.length > 0

    GridLayout {
        id: layout

        anchors.centerIn: parent
        flow: Utils.Theme.isSide ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: Utils.Theme.isTop ? -1 : 1
        rows: Utils.Theme.isSide ? -1 : 1
        columnSpacing: Utils.Theme.isTop ? Utils.Theme.spacingSmall : 0
        rowSpacing: Utils.Theme.isSide ? Utils.Theme.spacingSmall : 0

        Repeater {
            model: SystemTray.items

            Item {
                id: trayDelegate

                required property SystemTrayItem modelData
                required property int index

                Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
                Layout.preferredWidth: Utils.Theme.iconSize + 4
                Layout.preferredHeight: Utils.Theme.iconSize + 4

                Rectangle {
                    anchors.fill: parent
                    radius: Utils.Theme.roundingSmall
                    color: "transparent"
                }

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    source: {
                        const icon = trayDelegate.modelData.icon ?? "";
                        // Quickshell can't load custom icon paths — fall back to theme icon by id
                        if (icon.includes("?path="))
                            return "image://icon/" + trayDelegate.modelData.id;
                        return icon;
                    }
                    sourceSize.width: Utils.Theme.iconSize
                    sourceSize.height: Utils.Theme.iconSize
                    width: Utils.Theme.iconSize
                    height: Utils.Theme.iconSize
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                }

                Utils.MaterialIcon {
                    anchors.centerIn: parent
                    text: "apps"
                    font.pixelSize: Utils.Theme.iconSize
                    color: Utils.Theme.subtleText
                    visible: !trayIcon.visible
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        const gp = Utils.Theme.isSide
                            ? trayDelegate.mapToGlobal(0, trayDelegate.height / 2)
                            : trayDelegate.mapToGlobal(trayDelegate.width / 2, 0);
                        Services.Popout.show(`traymenu${trayDelegate.index}`,
                            Utils.Theme.isTop ? gp.x : 0,
                            Utils.Theme.isSide ? gp.y : 0,
                            root.screen);
                    }
                    onExited: {
                        Services.Popout.barItemHovered = false;
                        Services.Popout.requestClose();
                    }
                }
            }
        }
    }
}
