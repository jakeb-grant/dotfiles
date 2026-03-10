pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Services.Hypr.monitorFor(screen)
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? -1

    // Configured workspace IDs for this monitor from hyprctl workspacerules
    readonly property var configuredIds: Services.Hypr.workspaceIdsFor(monitor?.name ?? "")

    // Set of occupied workspace IDs (workspaces that actually exist right now)
    readonly property var occupiedIds: (Services.Hypr.workspaces?.values ?? [])
        .filter(w => w.monitor === root.monitor && !w.name.startsWith("special:"))
        .reduce((acc, w) => { acc[w.id] = true; return acc; }, {})

    // Deduped window icons per workspace: { wsId: ["icon1", "icon2", ...] }
    readonly property var windowIcons: {
        const toplevels = Services.Hypr.toplevels?.values ?? [];
        const map = {};
        for (const id of root.configuredIds) {
            const seen = new Set();
            const icons = [];
            const clients = toplevels.filter(c => c.workspace?.id === id);
            for (const c of clients) {
                const icon = Utils.Icons.getAppCategoryIcon(c.lastIpcObject.class, "terminal");
                if (!seen.has(icon)) {
                    seen.add(icon);
                    icons.push(icon);
                }
            }
            map[id] = icons;
        }
        return map;
    }

    // Pre-computed slot heights: 22 dot area + icon rows
    // Each icon row = 22px height + 2px column spacing
    readonly property var slotHeights: {
        const heights = [];
        for (const id of configuredIds) {
            const icons = windowIcons[id] ?? [];
            heights.push(28 + icons.length * 24);
        }
        return heights;
    }

    readonly property int activeIndex: {
        for (let i = 0; i < configuredIds.length; i++)
            if (configuredIds[i] === activeWsId) return i;
        return -1;
    }

    readonly property real indicatorY: {
        if (activeIndex < 0) return Utils.Theme.spacingNormal;
        let y = Utils.Theme.spacingNormal;
        for (let i = 0; i < activeIndex; i++)
            y += slotHeights[i] + Utils.Theme.spacingNormal;
        return y;
    }

    readonly property real indicatorHeight: activeIndex >= 0 ? (slotHeights[activeIndex] ?? 28) : 28

    implicitWidth: Utils.Theme.barInnerWidth
    implicitHeight: layout.implicitHeight + Utils.Theme.spacingNormal * 2
    radius: Utils.Theme.roundingNormal
    color: Utils.Theme.surface0

    Behavior on implicitHeight {
        Utils.Anim {}
    }

    // Active indicator — single sliding pill
    Rectangle {
        id: activeIndicator

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.indicatorY
        width: 28
        height: root.indicatorHeight
        radius: Utils.Theme.roundingFull
        color: Utils.Theme.blue
        visible: root.activeIndex >= 0

        Behavior on y {
            Utils.Anim {}
        }
        Behavior on height {
            Utils.Anim {}
        }
    }

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Utils.Theme.spacingNormal
        spacing: Utils.Theme.spacingNormal
        z: 1

        Repeater {
            model: root.configuredIds.length

            Item {
                id: wsSlot

                required property int index
                readonly property int wsId: root.configuredIds[index]
                readonly property bool active: wsId === root.activeWsId
                readonly property bool occupied: root.occupiedIds[wsId] ?? false
                readonly property var icons: root.windowIcons[wsId] ?? []
                readonly property int contentHeight: 28 + icons.length * 24

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 28
                Layout.preferredHeight: contentHeight

                Behavior on Layout.preferredHeight {
                    Utils.Anim {}
                }

                // Content column: dot + window icons
                Column {
                    id: wsContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    spacing: 2

                    // Workspace state icon
                    Item {
                        width: 28
                        height: 28

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1
                            text: "󰮯"
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: wsSlot.active ? 14 : wsSlot.occupied ? 12 : 8
                            color: wsSlot.active ? Utils.Theme.crust : wsSlot.occupied ? Utils.Theme.subtext0 : Utils.Theme.surface2

                            Behavior on font.pixelSize {
                                Utils.Anim {}
                            }
                            Behavior on color {
                                ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // Per-workspace window icons (deduped by category)
                    Repeater {
                        model: wsSlot.icons

                        Utils.MaterialIcon {
                            required property string modelData

                            text: modelData
                            font.pixelSize: Utils.Theme.iconSize
                            color: wsSlot.active ? Utils.Theme.crust : Utils.Theme.overlay1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: 28
                            height: 22

                            Behavior on color {
                                ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Hypr.dispatch("workspace " + wsSlot.wsId)
                }
            }
        }
    }
}
