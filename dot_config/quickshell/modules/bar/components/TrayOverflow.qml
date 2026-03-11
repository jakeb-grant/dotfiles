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

    implicitWidth: Utils.Theme.barInnerWidth
    implicitHeight: col.implicitHeight
    visible: col.visibleChildren.length > 0

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: Utils.Theme.spacingSmall

        Repeater {
            model: SystemTray.items

            Item {
                id: trayDelegate

                required property SystemTrayItem modelData
                required property int index

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Utils.Theme.iconSize + 4
                Layout.preferredHeight: Utils.Theme.iconSize + 4

                Rectangle {
                    anchors.fill: parent
                    radius: Utils.Theme.roundingSmall
                    color: hover.containsMouse ? Utils.Theme.surface1 : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
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
                    color: Utils.Theme.overlay1
                    visible: !trayIcon.visible
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        const globalPos = trayDelegate.mapToGlobal(0, trayDelegate.height / 2);
                        Services.Popout.show(`traymenu${trayDelegate.index}`, globalPos.y, root.screen);
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
