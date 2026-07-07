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
        // HyprlandMonitor objects are destroyed and recreated on monitor
        // remove/add; reading monitors.values here gives caller bindings a
        // dependency so they re-resolve instead of holding the dead object.
        void Hyprland.monitors.values;
        return Hyprland.monitorFor(screen);
    }

    // Get configured workspace IDs for a monitor
    function workspaceIdsFor(monitorName: string): list<int> {
        return root.workspaceRules[monitorName] ?? [];
    }

    // Setting running=true on an in-flight Process is a no-op, and that run
    // returns pre-reload rules — queue the request and re-run on exit.
    property bool _rulesRefreshQueued: false

    function refreshWorkspaceRules(): void {
        if (wsRulesProc.running) {
            root._rulesRefreshQueued = true;
            return;
        }
        wsRulesProc.running = true;
    }

    Process {
        id: wsRulesProc
        command: ["hyprctl", "workspacerules", "-j"]
        running: true

        onExited: {
            if (root._rulesRefreshQueued) {
                root._rulesRefreshQueued = false;
                wsRulesProc.running = true;
            }
        }

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

    // Belt-and-braces: dock transitions can interleave monitor events with
    // hyprpier's config rewrite; re-query once after the churn settles.
    Timer {
        id: rulesSettleTimer
        interval: 1000
        onTriggered: root.refreshWorkspaceRules()
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
                rulesSettleTimer.restart();
            }
        }
    }
}
