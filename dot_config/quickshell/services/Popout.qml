pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string currentName: ""
    property real centerY: 0
    property var activeScreen: null
    property bool barItemHovered: false
    property bool popoutHovered: false

    readonly property bool isOpen: currentName !== ""

    function show(name: string, y: real, screen: ShellScreen) {
        closeTimer.stop();
        currentName = name;
        centerY = y;
        activeScreen = screen;
        barItemHovered = true;
    }

    function requestClose() {
        closeTimer.restart();
    }

    function close() {
        closeTimer.stop();
        currentName = "";
        barItemHovered = false;
        popoutHovered = false;
        activeScreen = null;
    }

    Timer {
        id: closeTimer

        interval: 200
        onTriggered: {
            if (!root.barItemHovered && !root.popoutHovered)
                root.close();
        }
    }
}
