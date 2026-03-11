pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    property SystemTrayItem trayItem

    function navigateWithGrace() {
        Services.Popout.graceActive = true;
        graceTimer.restart();
    }

    property var _pendingHandle: null
    property bool _pendingPop: false

    function pushSubmenu(handle) {
        if (fadeOut.running || fadeIn.running) return;
        navigateWithGrace();
        _pendingHandle = handle;
        _pendingPop = false;
        fadeOut.start();
    }

    function popWithGrace() {
        if (fadeOut.running || fadeIn.running) return;
        navigateWithGrace();
        _pendingHandle = null;
        _pendingPop = true;
        fadeOut.start();
    }

    Component.onDestruction: {
        graceTimer.stop();
        Services.Popout.graceActive = false;
    }

    SequentialAnimation {
        id: fadeOut

        NumberAnimation {
            target: stack
            property: "opacity"
            from: 1; to: 0
            duration: 120
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: {
                if (root._pendingPop) {
                    stack.pop();
                } else if (root._pendingHandle) {
                    stack.push(subMenuComp.createObject(null, {
                        handle: root._pendingHandle,
                        isSubMenu: true
                    }));
                }
                root._pendingHandle = null;
                root._pendingPop = false;
                fadeIn.start();
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: stack
        property: "opacity"
        from: 0; to: 1
        duration: 150
        easing.type: Easing.OutCubic
    }

    Timer {
        id: graceTimer
        interval: 800
        onTriggered: {
            Services.Popout.graceActive = false;
            if (!Services.Popout.popoutHovered && !Services.Popout.barItemHovered)
                Services.Popout.requestClose();
        }
    }

    spacing: Utils.Theme.spacingSmall
    implicitWidth: Math.min(Math.max(stack.implicitWidth, 200), 400)

    RowLayout {
        spacing: Utils.Theme.spacingNormal
        Layout.fillWidth: true

        Image {
            source: {
                if (!root.trayItem) return "";
                const icon = root.trayItem.icon ?? "";
                if (icon.includes("?path="))
                    return "image://icon/" + root.trayItem.id;
                return icon;
            }
            sourceSize.width: 18
            sourceSize.height: 18
            width: 18
            height: 18
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: {
                if (!root.trayItem) return "?";
                const title = root.trayItem.title || root.trayItem.tooltipTitle || root.trayItem.id || "?";
                if (title === root.trayItem.id) {
                    return title.split("_")[0].charAt(0).toUpperCase() + title.split("_")[0].slice(1);
                }
                return title;
            }
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
            color: Utils.Theme.blue
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.surface0
        opacity: 0.6
    }

    StackView {
        id: stack

        Layout.fillWidth: true
        clip: true
        implicitWidth: currentItem?.implicitWidth ?? 200
        implicitHeight: currentItem?.implicitHeight ?? 0

        initialItem: SubMenu {
            handle: root.trayItem?.menu ?? null
        }

        // Disable per-item transitions — we animate the whole StackView instead
        pushEnter: Transition {}
        pushExit: Transition {}
        popEnter: Transition {}
        popExit: Transition {}
    }

    component SubMenu: ColumnLayout {
        id: menu

        property var handle
        property bool isSubMenu: false

        spacing: 1

        QsMenuOpener {
            id: menuOpener
            menu: menu.handle
        }

        Repeater {
            model: menuOpener.children

            Rectangle {
                id: menuItem

                required property QsMenuEntry modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: modelData.isSeparator ? separatorRect.height : 26
                Layout.topMargin: modelData.isSeparator ? 2 : 0
                Layout.bottomMargin: modelData.isSeparator ? 2 : 0
                implicitWidth: menuRow.implicitWidth + 20
                radius: 6
                color: "transparent"

                // Separator
                Rectangle {
                    id: separatorRect
                    visible: menuItem.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    height: 1
                    color: Utils.Theme.surface0
                    opacity: 0.5
                }

                // Hover background (animated opacity)
                Rectangle {
                    visible: !menuItem.modelData.isSeparator
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    radius: 6
                    color: Utils.Theme.surface1
                    opacity: (itemMouse.containsMouse && menuItem.modelData.enabled) ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    id: menuRow
                    visible: !menuItem.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Utils.Theme.spacingNormal

                    // Menu item icon
                    Image {
                        visible: menuItem.modelData.icon !== ""
                        source: menuItem.modelData.icon
                        sourceSize.width: 16
                        sourceSize.height: 16
                        width: 16
                        height: 16
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Menu item text
                    Text {
                        text: menuItem.modelData.text
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: 13
                        color: menuItem.modelData.enabled ? Utils.Theme.text : Utils.Theme.overlay0
                        opacity: menuItem.modelData.enabled ? 1.0 : 0.5
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Submenu chevron
                    Utils.MaterialIcon {
                        visible: menuItem.modelData.hasChildren
                        text: "chevron_right"
                        font.pixelSize: 16
                        color: Utils.Theme.overlay1
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: menuItem.modelData.enabled
                    cursorShape: menuItem.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    visible: !menuItem.modelData.isSeparator
                    enabled: menuItem.modelData.enabled
                    onClicked: {
                        if (menuItem.modelData.hasChildren) {
                            root.pushSubmenu(menuItem.modelData);
                        } else {
                            menuItem.modelData.triggered();
                        }
                    }
                }
            }
        }

        Text {
            visible: menuOpener.children.count === 0
            text: "No items"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.overlay0
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Utils.Theme.spacingSmall
            Layout.bottomMargin: Utils.Theme.spacingSmall
        }
    }

    // Back pill button
    Rectangle {
        visible: stack.depth > 1
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 30
        radius: Utils.Theme.roundingFull
        color: Utils.Theme.surface0
        border.width: 1
        border.color: backPillMouse.containsMouse ? Utils.Theme.surface2 : Utils.Theme.surface1

        Behavior on border.color {
            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
        }

        // Hover fill
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Utils.Theme.surface1
            opacity: backPillMouse.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }
        }

        Row {
            id: backPillRow
            anchors.centerIn: parent
            spacing: 4

            Utils.MaterialIcon {
                text: "arrow_back"
                font.pixelSize: 14
                color: Utils.Theme.subtext1
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Back"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Utils.Theme.subtext1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: backPillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.popWithGrace();
        }
    }

    Component {
        id: subMenuComp
        SubMenu {}
    }

    Text {
        visible: (root.trayItem?.hasMenu ?? false) === false
        text: "No menu available"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.overlay0
        font.italic: true
    }
}
