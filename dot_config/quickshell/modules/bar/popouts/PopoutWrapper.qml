import Quickshell
import QtQuick
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    required property real barWidth
    required property ShellScreen screen

    // active tracks hasCurrent (controls width), NOT currentName
    readonly property bool active: Services.Popout.isOpen && Services.Popout.activeScreen === screen

    // currentPopout checks currentName — stays valid during close retraction
    readonly property var currentPopout: contentArea.children.find(c => c.shouldBeActive) ?? null

    // Non-animated target sizes
    readonly property real nonAnimWidth: active
        ? (currentPopout?.implicitWidth ?? 0) + Utils.Theme.spacingLarge * 2 : 0
    readonly property real nonAnimHeight: (currentPopout?.implicitHeight ?? 0) + Utils.Theme.spacingLarge * 2

    // Expose geometry for Drawers.qml background + mask
    readonly property real popoutX: barWidth
    readonly property real popoutY: {
        if (!active && popoutContainer.implicitWidth <= 0) return 0;
        const border = Utils.Theme.borderThickness;
        const ideal = Services.Popout.centerY - nonAnimHeight / 2;
        return Math.max(border, Math.min(ideal, root.height - nonAnimHeight - border));
    }
    readonly property real popoutWidth: popoutContainer.implicitWidth
    readonly property real popoutHeight: popoutContainer.implicitWidth > 0 ? popoutContainer.implicitHeight : 0
    readonly property bool flushTop: popoutY <= Utils.Theme.borderThickness
    readonly property bool flushBottom: popoutY + popoutHeight >= root.height - Utils.Theme.borderThickness

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    // Clip container — all sizing driven by Behaviors
    Item {
        id: popoutContainer

        x: root.barWidth
        y: root.popoutY
        width: implicitWidth
        height: implicitHeight
        clip: true
        visible: implicitWidth > 0

        // Mutable curve/duration — swapped for close to decelerate at the end
        property var animCurve: Utils.Theme.animCurveEmphasized
        property int animDuration: Utils.Theme.animDuration

        implicitWidth: root.nonAnimWidth
        implicitHeight: root.nonAnimHeight

        // When retraction completes, clean up the service state and reset curve
        onImplicitWidthChanged: {
            if (implicitWidth <= 0 && !root.active) {
                Services.Popout.cleanup();
                animCurve = Utils.Theme.animCurveEmphasized;
                animDuration = Utils.Theme.animDuration;
            }
        }

        // Swap to decel curve on close for a slow finish
        Connections {
            target: root
            function onActiveChanged() {
                if (!root.active) {
                    popoutContainer.animCurve = Utils.Theme.animCurveEmphasizedDecel;
                    popoutContainer.animDuration = Utils.Theme.animDuration + 100;
                }
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: popoutContainer.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutContainer.animCurve
            }
        }

        Behavior on implicitHeight {
            enabled: popoutContainer.implicitWidth > 0

            NumberAnimation {
                duration: popoutContainer.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutContainer.animCurve
            }
        }

        Behavior on y {
            enabled: popoutContainer.implicitWidth > 0

            NumberAnimation {
                duration: popoutContainer.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutContainer.animCurve
            }
        }

        // Content area — fills container with padding
        Item {
            id: contentArea

            anchors.fill: parent
            anchors.margins: Utils.Theme.spacingLarge

            Popout {
                name: "clock"
                sourceComponent: clockComponent
            }
        }

        // Hover area — full container
        MouseArea {
            anchors.fill: parent
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

    Component {
        id: clockComponent
        ClockPopout {}
    }

    // Click-outside-to-close overlay
    MouseArea {
        anchors.fill: parent
        visible: root.active
        onClicked: Services.Popout.close()
        z: -1
    }

    // Popout component — individual Loader with scale+opacity transitions
    // On close: content stays visible, clipped by wrapper retraction.
    // Fade+scale only fires on popout SWITCH (currentName changes).
    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: Services.Popout.currentName === name

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        opacity: 0
        scale: 0.8
        active: false

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: Utils.Theme.animDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Utils.Theme.animCurveStandard
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: Utils.Theme.animDurationSmall
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Utils.Theme.animCurveStandard
                    }
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                }
            }
        ]
    }
}
