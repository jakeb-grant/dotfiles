pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces
    readonly property var toplevels: Hyprland.toplevels

    // Configured workspace IDs per monitor name, from hyprctl workspacerules
    // e.g. { "DP-2": [1,2,3,4,5], "DP-6": [6,7,8,9,10] }
    property var workspaceRules: ({})

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    // Get configured workspace IDs for a monitor
    function workspaceIdsFor(monitorName: string): list<int> {
        return root.workspaceRules[monitorName] ?? [];
    }

    function refreshWorkspaceRules(): void {
        wsRulesProc.running = true;
    }

    Process {
        id: wsRulesProc
        command: ["hyprctl", "workspacerules", "-j"]
        running: true

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const rules = JSON.parse(data);
                    const map = {};
                    for (const rule of rules) {
                        const wsId = parseInt(rule.workspaceString);
                        if (isNaN(wsId) || !rule.monitor) continue;
                        if (!map[rule.monitor]) map[rule.monitor] = [];
                        map[rule.monitor].push(wsId);
                    }
                    for (const mon in map)
                        map[mon].sort((a, b) => a - b);
                    root.workspaceRules = map;
                } catch (e) {}
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = event.name;
            if (["workspace", "workspacev2", "focusedmon", "moveworkspace", "renameworkspace",
                 "createworkspace", "destroyworkspace", "createworkspacev2", "destroyworkspacev2"].includes(name)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["activewindow", "activewindowv2", "openwindow", "closewindow",
                         "movewindow", "changefloatingmode", "fullscreen"].includes(name)) {
                Hyprland.refreshToplevels();
            }

            // Re-query workspace rules on monitor/config changes
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2",
                 "configreloaded"].includes(name)) {
                Hyprland.refreshMonitors();
                root.refreshWorkspaceRules();
            }
        }
    }
}
