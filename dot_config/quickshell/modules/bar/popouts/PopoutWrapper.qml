import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    required property real barWidth
    required property real barHeight
    required property ShellScreen screen

    readonly property bool active: Services.Popout.isOpen && Services.Popout.activeScreen === screen

    // Switch gate — while user is rapidly hovering between bar items, suppress
    // all popout content rendering until the cursor settles. Intermediate
    // popouts never become "shouldBeActive", so no in-transit artifacts.
    property bool switching: false
    property string _prevName: ""
    Timer {
        id: switchSettleTimer
        interval: 80
        onTriggered: root.switching = false
    }
    // currentPopout / sizes updated imperatively to avoid binding-loop with
    // size feedback (item.implicitSize → container.implicitSize → item layout
    // → item.implicitSize). Signal-driven updates break the chain.
    property var currentPopout: null
    property real _contentWidth: 0
    property real _contentHeight: 0
    property real _lastContentWidth: 0
    property real _lastContentHeight: 0

    function _updateCurrentPopout() {
        const n = Services.Popout.currentName;
        if (!n) { currentPopout = null; _contentWidth = 0; _contentHeight = 0; return; }
        const found = contentArea.children.find(c => (c.name ?? c.popoutName ?? "") === n) ?? null;
        currentPopout = found;
        _contentWidth = found?.implicitWidth ?? 0;
        _contentHeight = found?.implicitHeight ?? 0;
        if (_contentWidth > 0) _lastContentWidth = _contentWidth;
        if (_contentHeight > 0) _lastContentHeight = _contentHeight;
    }

    Connections {
        target: Services.Popout
        function onCurrentNameChanged() {
            const newName = Services.Popout.currentName;
            // Suppress only on switches between two popouts (both names non-empty).
            // Initial open ("" → x) and close (x → "") skip the gate.
            if (root._prevName !== "" && newName !== "" && root._prevName !== newName) {
                root.switching = true;
                switchSettleTimer.restart();
            }
            root._prevName = newName;
            root._updateCurrentPopout();
        }
    }

    Connections {
        target: root.currentPopout
        function onImplicitWidthChanged() {
            const w = root.currentPopout?.implicitWidth ?? 0;
            root._contentWidth = w;
            if (w > 0) root._lastContentWidth = w;
        }
        function onImplicitHeightChanged() {
            const h = root.currentPopout?.implicitHeight ?? 0;
            root._contentHeight = h;
            if (h > 0) root._lastContentHeight = h;
        }
    }

    // Effective content size — falls back to last-known so the panel keeps
    // its shape during close-out animation. First-open fallback is the
    // typical popout dimensions; once content arrives it takes over.
    readonly property real _effectiveWidth: (_contentWidth > 0 ? _contentWidth : _lastContentWidth) || Utils.Theme.popoutWidth
    readonly property real _effectiveHeight: (_contentHeight > 0 ? _contentHeight : _lastContentHeight) || Utils.Theme.popoutListHeight

    readonly property real _pad: Utils.Theme.spacingLarge
    readonly property real panelWidth: _effectiveWidth + _pad * 2
    readonly property real panelHeight: _effectiveHeight + _pad * 2

    // Panel position — perpendicular axis follows Popout.centerX/Y; parallel
    // axis sits one islandGap beyond the bar's far edge.
    readonly property real targetX: Utils.Theme.isSide
        ? Utils.Theme.barMargin + barWidth + Utils.Theme.islandGap
        : Math.max(Utils.Theme.barMargin,
            Math.min(Services.Popout.centerX - panelWidth / 2,
                root.width - panelWidth - Utils.Theme.barMargin))

    readonly property real targetY: Utils.Theme.isTop
        ? Utils.Theme.barMargin + barHeight + Utils.Theme.islandGap
        : Math.max(Utils.Theme.barMargin,
            Math.min(Services.Popout.centerY - panelHeight / 2,
                root.height - panelHeight - Utils.Theme.barMargin))

    anchors.fill: parent

    // Aggregate hover state across panel and bridge — close only when both unhovered.
    property bool panelHovered: false
    property bool bridgeHovered: false
    readonly property bool anyHovered: panelHovered || bridgeHovered
    onAnyHoveredChanged: {
        if (anyHovered) {
            Services.Popout.popoutHovered = true;
        } else {
            Services.Popout.popoutHovered = false;
            Services.Popout.requestClose();
        }
    }

    // Click-outside-to-close (full window when popout active)
    MouseArea {
        anchors.fill: parent
        visible: root.active
        onClicked: Services.Popout.close()
        z: 0
    }

    // Hover bridge — invisible Item spanning the islandGap so the cursor can
    // traverse from bar to panel without un-hovering.
    Item {
        id: hoverBridge
        x: Utils.Theme.isSide
            ? Utils.Theme.barMargin + root.barWidth
            : root.targetX
        y: Utils.Theme.isTop
            ? Utils.Theme.barMargin + root.barHeight
            : root.targetY
        width: Utils.Theme.isSide ? Utils.Theme.islandGap : root.panelWidth
        height: Utils.Theme.isTop ? Utils.Theme.islandGap : root.panelHeight
        visible: root.active
        z: 1

        HoverHandler {
            onHoveredChanged: root.bridgeHovered = hovered
        }
    }

    // Floating panel — rounded mantle rect, drop shadow, blooms from source.
    Rectangle {
        id: popoutContainer
        x: root.targetX
        y: root.targetY
        width: root.panelWidth
        height: root.panelHeight
        color: Utils.Theme.mantle
        radius: Utils.Theme.islandRounding
        z: 2

        property real animatedScale: root.active ? 1 : 0.8
        opacity: root.active ? 1 : 0
        visible: opacity > 0.001

        // Scale origin = source bar item center, in container-local coords.
        transform: Scale {
            origin.x: Services.Popout.centerX - popoutContainer.x
            origin.y: Services.Popout.centerY - popoutContainer.y
            xScale: popoutContainer.animatedScale
            yScale: popoutContainer.animatedScale
        }

        Behavior on animatedScale {
            NumberAnimation {
                duration: Utils.Theme.animDuration
                easing.type: root.active ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.2
            }
        }

        Behavior on opacity {
            SequentialAnimation {
                NumberAnimation {
                    duration: Utils.Theme.animDurationSmall
                    easing.type: root.active ? Easing.OutCubic : Easing.InCubic
                }
                ScriptAction {
                    script: {
                        if (!root.active
                                && (Services.Popout.activeScreen === root.screen
                                    || Services.Popout.activeScreen === null)) {
                            Services.Popout.cleanup();
                        }
                    }
                }
            }
        }

        Behavior on x {
            enabled: Utils.Theme.isTop && root.active
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            enabled: Utils.Theme.isSide && root.active
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        // Smooth size morph on switch — old popout shrinks/grows in step
        // with the new one's appearance, eliminating cross-fade ghosts.
        Behavior on width {
            enabled: root.active && popoutContainer.opacity > 0.9
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            enabled: root.active && popoutContainer.opacity > 0.9
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Utils.Theme.islandShadowColor
            shadowOpacity: Utils.Theme.islandShadowOpacity
            blurMax: Utils.Theme.islandShadowBlur
            shadowVerticalOffset: Utils.Theme.islandShadowY
            shadowHorizontalOffset: 0
            autoPaddingEnabled: true
        }

        HoverHandler {
            onHoveredChanged: root.panelHovered = hovered
        }

        // Content area — Popouts overlap here, cross-fading between active ones.
        Item {
            id: contentArea
            anchors.fill: parent
            anchors.margins: root._pad

            Popout { name: "system";     sourceComponent: systemComponent }
            Popout { name: "volume";     sourceComponent: volumeComponent }
            Popout { name: "brightness"; sourceComponent: brightnessComponent }
            Popout { name: "battery";    sourceComponent: batteryComponent }
            Popout { name: "calendar";   sourceComponent: calendarComponent }
            Popout { name: "wifi";       sourceComponent: wifiComponent }
            Popout { name: "bluetooth";  sourceComponent: bluetoothComponent }
            Popout { name: "power";      sourceComponent: powerComponent }

            // Per-tray-item popout menus (one per SystemTray item)
            Repeater {
                model: SystemTray.items

                Loader {
                    id: trayLoader

                    required property SystemTrayItem modelData
                    required property int index

                    readonly property string popoutName: `traymenu${index}`
                    readonly property bool shouldBeActive: !root.switching
                        && Services.Popout.currentName === popoutName
                        && Services.Popout.activeScreen === root.screen

                    anchors.centerIn: parent

                    active: false
                    opacity: 0
                    visible: opacity > 0.001

                    sourceComponent: TrayMenuPopout {
                        trayItem: trayLoader.modelData
                    }

                    // Force recreation when reopening (per-instance menu state)
                    Connections {
                        target: Services.Popout
                        function onIsOpenChanged() {
                            if (Services.Popout.isOpen && trayLoader.shouldBeActive) {
                                trayLoader.active = false;
                                trayLoader.active = true;
                            }
                        }
                    }

                    states: State {
                        name: "active"
                        when: trayLoader.shouldBeActive
                        PropertyChanges {
                            trayLoader.active: true
                            trayLoader.opacity: 1
                        }
                    }

                    transitions: [
                        Transition {
                            from: ""
                            to: "active"
                            SequentialAnimation {
                                PropertyAction { target: trayLoader; property: "active" }
                                PauseAnimation { duration: 16 }
                                PropertyAction { target: trayLoader; property: "opacity" }
                            }
                        },
                        Transition {
                            from: "active"
                            to: ""
                            SequentialAnimation {
                                PropertyAction { target: trayLoader; property: "opacity" }
                                PauseAnimation { duration: 50 }
                                PropertyAction { target: trayLoader; property: "active" }
                            }
                        }
                    ]
                }
            }
        }
    }

    Component { id: systemComponent;     SystemPopout {} }
    Component { id: volumeComponent;     VolumePopout {} }
    Component { id: brightnessComponent; BrightnessPopout {} }
    Component { id: batteryComponent;    BatteryPopout {} }
    Component { id: calendarComponent;   CalendarPopout {} }
    Component { id: wifiComponent;       WifiPopout {} }
    Component { id: bluetoothComponent;  BluetoothPopout {} }
    Component { id: powerComponent;      PowerPopout {} }

    // Popout primitive — Loader that opacity-fades when active. The scale
    // bloom lives on the container, not here, to avoid double-animation.
    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: !root.switching
            && Services.Popout.currentName === name
            && Services.Popout.activeScreen === root.screen

        anchors.centerIn: parent

        active: false
        opacity: 0
        visible: opacity > 0.001

        states: State {
            name: "active"
            when: popout.shouldBeActive
            PropertyChanges {
                popout.active: true
                popout.opacity: 1
            }
        }

        transitions: [
            // Switch IN: load, give one frame for layout, then snap opacity to 1.
            // The container's scale/fade handles visible "appearance" — content
            // inside snaps so fast hovers don't leave fade trails.
            Transition {
                from: ""
                to: "active"
                SequentialAnimation {
                    PropertyAction { target: popout; property: "active" }
                    PauseAnimation { duration: 16 }
                    PropertyAction { target: popout; property: "opacity" }
                }
            },
            // Switch OUT: snap opacity to 0 instantly, then unload after a short
            // grace period so any final renders complete.
            Transition {
                from: "active"
                to: ""
                SequentialAnimation {
                    PropertyAction { target: popout; property: "opacity" }
                    PauseAnimation { duration: 50 }
                    PropertyAction { target: popout; property: "active" }
                }
            }
        ]
    }
}
