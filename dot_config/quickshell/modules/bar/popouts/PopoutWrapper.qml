import Quickshell
import QtQuick
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    required property real barWidth
    required property ShellScreen screen

    readonly property bool active: Services.Popout.isOpen && Services.Popout.activeScreen === screen

    // Expose geometry for Drawers.qml background + mask
    readonly property real popoutX: barWidth
    readonly property real popoutY: {
        if (!active && popoutContainer.implicitWidth <= 0) return 0;
        const border = Utils.Theme.borderThickness;
        const ideal = Services.Popout.centerY - popoutHeight / 2;
        return Math.max(border, Math.min(ideal, root.height - popoutHeight - border));
    }
    readonly property real popoutWidth: popoutContainer.implicitWidth
    readonly property real popoutHeight: popoutContainer.implicitWidth > 0 ? popoutContainer.targetHeight : 0
    readonly property bool flushTop: popoutY <= Utils.Theme.borderThickness
    readonly property bool flushBottom: popoutY + popoutHeight >= root.height - Utils.Theme.borderThickness

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    onActiveChanged: {
        if (active)
            popoutContainer.open();
        else
            popoutContainer.close();
    }

    Item {
        id: popoutContainer

        // Cache name so content survives during close animation
        property string displayedName: ""

        readonly property real targetWidth: (popoutLoader.item?.implicitWidth ?? 0) + Utils.Theme.spacingLarge * 2
        readonly property real targetHeight: (popoutLoader.item?.implicitHeight ?? 0) + Utils.Theme.spacingLarge * 2

        x: root.barWidth
        y: root.popoutY
        width: implicitWidth
        height: targetHeight
        clip: true
        visible: implicitWidth > 0

        Behavior on implicitWidth {
            id: widthBehavior

            NumberAnimation {
                duration: Utils.Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        function open() {
            closeAnim.stop();
            widthBehavior.enabled = true;
            displayedName = Services.Popout.currentName;
            popoutLoader.active = true;
            implicitWidth = targetWidth;
            contentArea.opacity = 1;
        }

        function close() {
            closeAnim.start();
        }

        SequentialAnimation {
            id: closeAnim

            // Fade content out first
            NumberAnimation {
                target: contentArea
                property: "opacity"
                to: 0
                duration: 100
                easing.type: Easing.InCubic
            }
            // Disable Behavior so we control retraction timing
            PropertyAction {
                target: widthBehavior
                property: "enabled"
                value: false
            }
            // Retract width
            NumberAnimation {
                target: popoutContainer
                property: "implicitWidth"
                to: 0
                duration: Utils.Theme.animDurationFast
                easing.type: Easing.InCubic
            }
            // Cleanup
            ScriptAction {
                script: {
                    popoutLoader.active = false;
                    popoutContainer.displayedName = "";
                    widthBehavior.enabled = true;
                }
            }
        }

        // Content area — pinned to full target size so it never squashes
        Item {
            id: contentArea

            width: popoutContainer.targetWidth
            height: popoutContainer.targetHeight
            opacity: 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Utils.Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                id: popoutLoader

                active: false
                anchors.centerIn: parent

                sourceComponent: {
                    switch (popoutContainer.displayedName) {
                        case "clock": return clockPopout;
                        default: return null;
                    }
                }
            }
        }

        // Hover area — full target size so it works during animation
        MouseArea {
            width: popoutContainer.targetWidth
            height: popoutContainer.targetHeight
            hoverEnabled: true

            onEntered: {
                Services.Popout.popoutHovered = true;
            }
            onExited: {
                Services.Popout.popoutHovered = false;
                Services.Popout.requestClose();
            }
        }
    }

    // Click-outside-to-close overlay
    MouseArea {
        anchors.fill: parent
        visible: root.active
        onClicked: Services.Popout.close()
        z: -1
    }

    Component {
        id: clockPopout
        ClockPopout {}
    }
}
