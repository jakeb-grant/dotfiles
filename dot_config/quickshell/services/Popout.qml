pragma Singleton

import Quickshell
import QtQuick
import qs.utils as Utils

Singleton {
    id: root

    // currentName stays set during close so content survives retraction.
    // hasCurrent controls whether the wrapper is open.
    property string currentName: ""
    property bool hasCurrent: false
    property real centerX: 0
    property real centerY: 0
    property var activeScreen: null
    property bool barItemHovered: false
    property bool popoutHovered: false
    property bool graceActive: false

    readonly property bool isOpen: hasCurrent

    function show(name: string, x: real, y: real, screen: ShellScreen) {
        closeTimer.stop();
        // Set screen and open state BEFORE currentName so that shouldBeActive
        // (which checks both currentName and activeScreen) evaluates with
        // the correct screen — prevents wrong-monitor Loader activation.
        activeScreen = screen;
        hasCurrent = true;
        centerX = x;
        centerY = y;
        currentName = name;
        barItemHovered = true;
    }

    // Show anchored to a bar item — maps its center to window coords along
    // the bar's parallel axis. The standard onEntered handler for bar items.
    function showFrom(item: Item, name: string, screen: ShellScreen) {
        const gp = Utils.Theme.isSide
            ? item.mapToItem(null, 0, item.height / 2)
            : item.mapToItem(null, item.width / 2, 0);
        show(name,
            Utils.Theme.isTop ? gp.x : 0,
            Utils.Theme.isSide ? gp.y : 0,
            screen);
    }

    function requestClose() {
        closeTimer.restart();
    }

    // Counterpart to show()'s barItemHovered = true — the standard onExited
    // handler for bar items.
    function barItemExited() {
        barItemHovered = false;
        requestClose();
    }

    function close() {
        closeTimer.stop();
        hasCurrent = false;
        barItemHovered = false;
        popoutHovered = false;
        graceActive = false;
        // currentName, centerY, activeScreen cleared by wrapper after retraction completes
    }

    function cleanup() {
        currentName = "";
        activeScreen = null;
    }

    Timer {
        id: closeTimer

        interval: 200
        onTriggered: {
            if (!root.barItemHovered && !root.popoutHovered && !root.graceActive)
                root.close();
        }
    }
}
