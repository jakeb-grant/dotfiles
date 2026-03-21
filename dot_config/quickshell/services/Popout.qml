pragma Singleton

import Quickshell
import QtQuick

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
        currentName = name;
        centerX = x;
        centerY = y;
        activeScreen = screen;
        hasCurrent = true;
        barItemHovered = true;
    }

    function requestClose() {
        closeTimer.restart();
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
