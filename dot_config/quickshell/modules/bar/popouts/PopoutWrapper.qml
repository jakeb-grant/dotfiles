import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    required property real barWidth
    required property real barHeight
    required property ShellScreen screen

    // active tracks hasCurrent (controls width), NOT currentName
    readonly property bool active: Services.Popout.isOpen && Services.Popout.activeScreen === screen

    // currentPopout checks currentName — stays valid during close retraction
    readonly property var currentPopout: contentArea.children.find(c => c.shouldBeActive) ?? null

    // Track raw content size — falls back to last valid value during Loader activation frame
    readonly property real _contentWidth: currentPopout?.implicitWidth ?? 0
    readonly property real _contentHeight: currentPopout?.implicitHeight ?? 0
    property real _lastContentWidth: 0
    property real _lastContentHeight: 0

    on_ContentWidthChanged: if (_contentWidth > 0) _lastContentWidth = _contentWidth
    on_ContentHeightChanged: if (_contentHeight > 0) _lastContentHeight = _contentHeight

    // Non-animated target sizes
    // Side mode: width is the animated axis (0 when closed), height is content-driven
    // Top mode: height is the animated axis (0 when closed), width is content-driven
    readonly property real nonAnimWidth: Utils.Theme.isSide
        ? (active ? (_contentWidth > 0 ? _contentWidth : _lastContentWidth) + Utils.Theme.spacingLarge * 2 : 0)
        : ((_contentWidth > 0 ? _contentWidth : (active ? _lastContentWidth : 0)) + Utils.Theme.spacingLarge * 2)
    readonly property real nonAnimHeight: Utils.Theme.isTop
        ? (active ? (_contentHeight > 0 ? _contentHeight : _lastContentHeight) + Utils.Theme.spacingLarge * 2 : 0)
        : ((_contentHeight > 0 ? _contentHeight : (active ? _lastContentHeight : 0)) + Utils.Theme.spacingLarge * 2)

    // ── Side mode: vertical positioning (popout right of bar) ──
    readonly property real targetY: {
        if (!active && popoutContainer.implicitWidth <= 0) return 0;
        const border = Utils.Theme.borderThickness;
        const ideal = Services.Popout.centerY - nonAnimHeight / 2;
        return Math.max(border, Math.min(ideal, root.height - nonAnimHeight - border));
    }

    readonly property bool flushTop: Utils.Theme.isSide && targetY <= Utils.Theme.borderThickness
    readonly property bool flushBottom: Utils.Theme.isSide && targetY + nonAnimHeight >= root.height - Utils.Theme.borderThickness

    // ── Top mode: horizontal positioning (popout below bar) ──
    readonly property real targetX: {
        if (!active && popoutContainer.implicitWidth <= 0) return 0;
        const border = Utils.Theme.borderThickness;
        const ideal = Services.Popout.centerX - nonAnimWidth / 2;
        return Math.max(border, Math.min(ideal, root.width - nonAnimWidth - border));
    }

    readonly property bool flushLeft: Utils.Theme.isTop && targetX <= Utils.Theme.borderThickness
    readonly property bool flushRight: Utils.Theme.isTop && targetX + nonAnimWidth >= root.width - Utils.Theme.borderThickness

    // Expose geometry for Drawers.qml background + mask
    readonly property real popoutX: Utils.Theme.isSide ? barWidth : popoutContainer.x
    readonly property real popoutY: Utils.Theme.isTop ? barHeight : popoutContainer.y
    readonly property real popoutWidth: popoutContainer.implicitWidth
    readonly property real popoutHeight: popoutContainer.implicitWidth > 0 ? popoutContainer.implicitHeight : 0

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    // Clip container — all sizing driven by Behaviors
    Item {
        id: popoutContainer
        z: 1

        x: Utils.Theme.isSide
            ? root.barWidth
            : (root.flushRight
                ? root.width - implicitWidth - Utils.Theme.borderThickness
                : root.flushLeft
                    ? Utils.Theme.borderThickness
                    : root.targetX)
        y: Utils.Theme.isTop
            ? root.barHeight
            : (root.flushBottom
                ? root.height - implicitHeight - Utils.Theme.borderThickness
                : root.flushTop
                    ? Utils.Theme.borderThickness
                    : root.targetY)
        width: implicitWidth
        height: implicitHeight
        clip: true
        visible: Utils.Theme.isSide ? implicitWidth > 0 : implicitHeight > 0

        // Mutable curve/duration — swapped for close to decelerate at the end
        property var animCurve: Utils.Theme.animCurveEmphasized
        property int animDuration: Utils.Theme.animDuration
        // Separate duration for height/Y during switches (faster reshape)
        property int reshapeDuration: Utils.Theme.animDuration

        implicitWidth: root.nonAnimWidth
        implicitHeight: root.nonAnimHeight

        // When retraction completes, clean up the service state and reset curve
        function _checkRetracted() {
            const retracted = Utils.Theme.isSide ? implicitWidth <= 0 : implicitHeight <= 0;
            if (retracted && !root.active) {
                Services.Popout.cleanup();
                animCurve = Utils.Theme.animCurveEmphasized;
                animDuration = Utils.Theme.animDuration;
                reshapeDuration = Utils.Theme.animDuration;
            }
        }
        onImplicitWidthChanged: _checkRetracted()
        onImplicitHeightChanged: _checkRetracted()

        // React to close and switch events
        Connections {
            target: root
            function onActiveChanged() {
                if (!root.active) {
                    // Swap to decel curve on close for a slow finish
                    popoutContainer.animCurve = Utils.Theme.animCurveEmphasizedDecel;
                    popoutContainer.animDuration = Utils.Theme.animDuration + 100;
                    popoutContainer.reshapeDuration = Utils.Theme.animDuration + 100;
                }
            }
        }

        Connections {
            target: Services.Popout
            function onCurrentNameChanged() {
                // If switching while open, use fast reshape for height/Y
                if (root.active && Services.Popout.currentName !== "") {
                    popoutContainer.animCurve = Utils.Theme.animCurveEmphasized;
                    popoutContainer.animDuration = Utils.Theme.animDuration;
                    popoutContainer.reshapeDuration = Utils.Theme.animDurationFast;
                }
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Utils.Theme.isSide ? popoutContainer.animDuration : popoutContainer.reshapeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutContainer.animCurve
            }
        }

        Behavior on implicitHeight {
            enabled: Utils.Theme.isSide ? popoutContainer.implicitWidth > 0 : true

            NumberAnimation {
                duration: Utils.Theme.isTop ? popoutContainer.animDuration : popoutContainer.reshapeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutContainer.animCurve
            }
        }

        Behavior on x {
            enabled: Utils.Theme.isTop && popoutContainer.implicitWidth > 0 && !root.flushLeft && !root.flushRight

            NumberAnimation {
                duration: popoutContainer.reshapeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutContainer.animCurve
            }
        }

        Behavior on y {
            enabled: Utils.Theme.isSide && popoutContainer.implicitWidth > 0 && !root.flushTop && !root.flushBottom

            NumberAnimation {
                duration: popoutContainer.reshapeDuration
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
                name: "system"
                sourceComponent: systemComponent
            }

            Popout {
                name: "volume"
                sourceComponent: volumeComponent
            }

            Popout {
                name: "brightness"
                sourceComponent: brightnessComponent
            }

            Popout {
                name: "battery"
                sourceComponent: batteryComponent
            }

            Popout {
                name: "calendar"
                sourceComponent: calendarComponent
            }

            Popout {
                name: "wifi"
                sourceComponent: wifiComponent
            }

            Popout {
                name: "bluetooth"
                sourceComponent: bluetoothComponent
            }

            Popout {
                name: "power"
                sourceComponent: powerComponent
            }

            // Per-tray-item popout menus (one per SystemTray item)
            Repeater {
                model: SystemTray.items

                Item {
                    id: trayWrapper

                    required property SystemTrayItem modelData
                    required property int index

                    readonly property string popoutName: `traymenu${index}`
                    readonly property bool shouldBeActive: Services.Popout.currentName === popoutName

                    // Expose for currentPopout lookup
                    implicitWidth: trayLoader.item?.implicitWidth ?? 0
                    implicitHeight: trayLoader.item?.implicitHeight ?? 0

                    anchors.verticalCenter: parent?.verticalCenter
                    anchors.right: parent?.right

                    opacity: 0
                    scale: 0.8

                    Loader {
                        id: trayLoader
                        active: false
                        sourceComponent: trayMenuComp

                        // Force recreation on open
                        Connections {
                            target: Services.Popout

                            function onIsOpenChanged() {
                                if (Services.Popout.isOpen && trayWrapper.shouldBeActive) {
                                    trayLoader.sourceComponent = null;
                                    trayLoader.sourceComponent = trayMenuComp;
                                }
                            }
                        }

                        Component {
                            id: trayMenuComp
                            TrayMenuPopout {
                                trayItem: trayWrapper.modelData
                            }
                        }
                    }

                    states: State {
                        name: "active"
                        when: trayWrapper.shouldBeActive

                        PropertyChanges {
                            trayLoader.active: true
                            trayWrapper.opacity: 1
                            trayWrapper.scale: 1
                        }
                    }

                    transitions: [
                        Transition {
                            from: ""
                            to: "active"

                            SequentialAnimation {
                                PropertyAction {
                                    target: trayLoader
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
                                    target: trayLoader
                                    property: "active"
                                }
                            }
                        }
                    ]
                }
            }

            // Hover area — full container
            HoverHandler {
                id: popoutHover
                onHoveredChanged: {
                    if (hovered) {
                        Services.Popout.popoutHovered = true;
                    } else {
                        Services.Popout.popoutHovered = false;
                        Services.Popout.requestClose();
                    }
                }
            }
        }
    }

    Component {
        id: systemComponent
        SystemPopout {}
    }

    Component {
        id: volumeComponent
        VolumePopout {}
    }

    Component {
        id: brightnessComponent
        BrightnessPopout {}
    }

    Component {
        id: batteryComponent
        BatteryPopout {}
    }

    Component {
        id: calendarComponent
        CalendarPopout {}
    }

    Component {
        id: wifiComponent
        WifiPopout {}
    }

    Component {
        id: bluetoothComponent
        BluetoothPopout {}
    }

    Component {
        id: powerComponent
        PowerPopout {}
    }

    // Click-outside-to-close overlay
    MouseArea {
        anchors.fill: parent
        visible: root.active
        onClicked: Services.Popout.close()
        z: 0
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
