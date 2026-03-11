pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

ColumnLayout {
    id: root

    property SystemTrayItem trayItem

    spacing: 4
    implicitWidth: Math.min(Math.max(col.implicitWidth, 180), 400)

    Text {
        text: "Menu for: " + (root.trayItem?.title ?? root.trayItem?.id ?? "?")
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSize
        font.bold: true
        color: Utils.Theme.text
    }

    Text {
        text: "hasMenu: " + (root.trayItem?.hasMenu ?? "null")
        font.family: Utils.Theme.fontFamily
        font.pixelSize: 11
        color: Utils.Theme.subtext0
    }

    Text {
        text: "Menu entries: " + (menuOpener.children?.count ?? 0)
        font.family: Utils.Theme.fontFamily
        font.pixelSize: 11
        color: Utils.Theme.subtext0
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface1
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.trayItem?.menu ?? null
    }

    ColumnLayout {
        id: col
        spacing: 2

        Repeater {
            model: menuOpener.children

            Rectangle {
                id: menuItem

                required property QsMenuEntry modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: modelData.isSeparator ? 1 : 28
                implicitWidth: menuRow.implicitWidth + 16
                radius: 4
                color: modelData.isSeparator
                    ? Utils.Theme.surface1
                    : itemMouse.containsMouse
                        ? Utils.Theme.surface1
                        : "transparent"

                Row {
                    id: menuRow
                    visible: !menuItem.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: menuItem.modelData.text
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: 12
                        color: menuItem.modelData.enabled ? Utils.Theme.text : Utils.Theme.overlay0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: menuItem.modelData.hasChildren
                        text: ">"
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: 12
                        color: Utils.Theme.overlay0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    visible: !menuItem.modelData.isSeparator
                    onClicked: {
                        console.log("MENU CLICK: " + menuItem.modelData.text);
                        menuItem.modelData.triggered();
                    }
                }
            }
        }
    }

    Text {
        visible: (menuOpener.children?.count ?? 0) === 0
        text: "No menu entries found"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: 12
        color: Utils.Theme.overlay0
        font.italic: true
    }
}
