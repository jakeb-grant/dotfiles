pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.bar.popouts.components
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
            duration: Utils.Theme.animDurationFast
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
        duration: Utils.Theme.animDurationFast
        easing.type: Easing.OutCubic
    }

    Timer {
        id: graceTimer
        interval: Utils.Theme.animDurationSpin
        onTriggered: {
            Services.Popout.graceActive = false;
            if (!Services.Popout.popoutHovered && !Services.Popout.barItemHovered)
                Services.Popout.requestClose();
        }
    }

    spacing: Utils.Theme.spacingSmall
    implicitWidth: Math.min(Math.max(stack.implicitWidth, Utils.Theme.trayMenuMinWidth), Utils.Theme.trayMenuMaxWidth)

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
            sourceSize.width: Utils.Theme.popoutTitleSize
            sourceSize.height: Utils.Theme.popoutTitleSize
            width: Utils.Theme.popoutTitleSize
            height: Utils.Theme.popoutTitleSize
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
            font.pixelSize: Utils.Theme.headerFontSize
            font.bold: true
            color: Utils.Theme.text
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Separator {}

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

        // Whether any entry in this menu has a resolvable icon
        property bool hasAnyIcon: false

        spacing: Utils.Theme.spacingTiny

        QsMenuOpener {
            id: menuOpener
            menu: menu.handle
        }

        Repeater {
            id: menuRepeater
            model: menuOpener.children

            ListRow {
                id: menuItem

                required property QsMenuEntry modelData
                required property int index

                // Optimistic local check state for immediate visual feedback
                property int _localCheckState: modelData.checkState

                Layout.fillWidth: true
                Layout.preferredHeight: modelData.isSeparator ? 1 : Utils.Theme.trayMenuItemHeight
                Layout.topMargin: modelData.isSeparator ? 2 : 0
                Layout.bottomMargin: modelData.isSeparator ? 2 : 0
                implicitWidth: contentImplicitWidth + 20
                interactive: modelData.enabled && !modelData.isSeparator
                hoverPadding: Utils.Theme.spacingTiny

                onClicked: {
                    if (menuItem.modelData.hasChildren) {
                        root.pushSubmenu(menuItem.modelData);
                    } else {
                        // Optimistic toggle for checkbox/radio
                        if (menuItem.modelData.buttonType === 1) {
                            menuItem._localCheckState = menuItem._localCheckState === 2 ? 0 : 2;
                        } else if (menuItem.modelData.buttonType === 2) {
                            // Uncheck sibling radios via Repeater delegates
                            for (let i = 0; i < menuRepeater.count; i++) {
                                const item = menuRepeater.itemAt(i);
                                if (item && item !== menuItem && item.modelData.buttonType === 2)
                                    item._localCheckState = 0;
                            }
                            menuItem._localCheckState = 2;
                        }
                        menuItem.modelData.triggered();
                    }
                }

                // Separator entry
                Rectangle {
                    visible: menuItem.modelData.isSeparator
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Utils.Theme.separator
                }

                // Menu item icon — only load if icon exists in theme cache.
                // Reserve space if other entries in this menu have icons.
                Item {
                    visible: !menuItem.modelData.isSeparator && menu.hasAnyIcon
                    implicitWidth: 16
                    implicitHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        readonly property string iconSrc: menuItem.modelData.icon
                        readonly property string iconName: {
                            const s = iconSrc;
                            if (s === "") return "";
                            if (s.startsWith("image://icon/")) {
                                const rest = s.substring("image://icon/".length);
                                const q = rest.indexOf("?");
                                return q >= 0 ? rest.substring(0, q) : rest;
                            }
                            return s;
                        }
                        readonly property bool knownIcon: iconSrc !== "" && (iconName in Services.IconCache.icons || iconSrc.startsWith("image://qsimage/"))
                        visible: knownIcon
                        source: knownIcon ? iconSrc : ""
                        anchors.fill: parent

                        onKnownIconChanged: {
                            if (knownIcon) menu.hasAnyIcon = true;
                        }
                    }
                }

                // Checkbox / radio indicator
                // buttonType: 0=None, 1=CheckBox, 2=RadioButton
                // checkState: 0=Unchecked, 2=Checked
                Utils.MaterialIcon {
                    visible: !menuItem.modelData.isSeparator && menuItem.modelData.buttonType !== 0
                    text: {
                        if (menuItem.modelData.buttonType === 1)
                            return menuItem._localCheckState === 2 ? "check_box" : "check_box_outline_blank";
                        if (menuItem.modelData.buttonType === 2)
                            return menuItem._localCheckState === 2 ? "radio_button_checked" : "radio_button_unchecked";
                        return "";
                    }
                    font.pixelSize: Utils.Theme.headerFontSize
                    color: menuItem._localCheckState === 2 ? Utils.Theme.accent : Utils.Theme.subtleText
                    Layout.alignment: Qt.AlignVCenter
                }

                // Menu item text
                Text {
                    visible: !menuItem.modelData.isSeparator
                    text: menuItem.modelData.text
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.listFontSize
                    color: menuItem.modelData.enabled ? Utils.Theme.text : Utils.Theme.disabledText
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Submenu chevron
                Utils.MaterialIcon {
                    visible: menuItem.modelData.hasChildren
                    text: "chevron_right"
                    font.pixelSize: Utils.Theme.headerFontSize
                    color: Utils.Theme.subtleText
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        EmptyLabel {
            visible: menuOpener.children.count === 0
            text: "No items"
            color: Utils.Theme.disabledText
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Utils.Theme.spacingSmall
            Layout.bottomMargin: Utils.Theme.spacingSmall
        }
    }

    PillButton {
        visible: stack.depth > 1
        Layout.fillWidth: true
        Layout.topMargin: Utils.Theme.spacingSmall
        icon: "arrow_back"
        label: "Back"
        onClicked: root.popWithGrace()
    }

    Component {
        id: subMenuComp
        SubMenu {}
    }

    EmptyLabel {
        visible: (root.trayItem?.hasMenu ?? false) === false
        text: "No menu available"
        color: Utils.Theme.disabledText
    }
}
