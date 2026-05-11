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

    // ── Workspace entrance cascade ──
    property bool entranceReady: false
    property int _wsAnimStep: -1

    Timer {
        id: wsEntranceTimer
        interval: 55
        repeat: true
        running: root.entranceReady && root._wsAnimStep < root.configuredIds.length
        onTriggered: root._wsAnimStep++
    }

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

    // Pre-computed slot sizes along the layout axis
    // Side mode: height = 28 dot area + icon rows (each 24px)
    // Top mode: width = 28 dot area + icon columns (each 24px)
    readonly property var slotHeights: {
        const heights = [];
        for (const id of configuredIds) {
            const icons = windowIcons[id] ?? [];
            heights.push(28 + icons.length * 24);
        }
        return heights;
    }

    readonly property var slotWidths: {
        const widths = [];
        for (const id of configuredIds) {
            const icons = windowIcons[id] ?? [];
            widths.push(28 + icons.length * 24);
        }
        return widths;
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

    readonly property real indicatorHeight: {
        const base = activeIndex >= 0 ? (slotHeights[activeIndex] ?? 28) : 28;
        const icons = activeIndex >= 0 ? (windowIcons[configuredIds[activeIndex]] ?? []) : [];
        return base + (icons.length > 0 ? 3 : 0);
    }

    readonly property real indicatorX: {
        if (activeIndex < 0) return Utils.Theme.spacingNormal;
        let x = Utils.Theme.spacingNormal;
        for (let i = 0; i < activeIndex; i++)
            x += slotWidths[i] + Utils.Theme.spacingNormal;
        return x;
    }

    readonly property real indicatorWidth: {
        const base = activeIndex >= 0 ? (slotWidths[activeIndex] ?? 28) : 28;
        const icons = activeIndex >= 0 ? (windowIcons[configuredIds[activeIndex]] ?? []) : [];
        return base + (icons.length > 0 ? 3 : 0);
    }

    implicitWidth: Utils.Theme.isSide ? Utils.Theme.barInnerWidth : (layout.implicitWidth + Utils.Theme.spacingNormal * 2)
    implicitHeight: Utils.Theme.isTop ? Utils.Theme.barInnerWidth : (layout.implicitHeight + Utils.Theme.spacingNormal * 2)
    radius: Utils.Theme.roundingNormal
    color: Utils.Theme.pillBg

    Behavior on implicitHeight {
        Utils.Anim {}
    }
    Behavior on implicitWidth {
        Utils.Anim {}
    }

    // Active indicator — single sliding pill
    Rectangle {
        id: activeIndicator

        x: Utils.Theme.isTop ? root.indicatorX : (parent.width - 28) / 2
        y: Utils.Theme.isSide ? root.indicatorY : (parent.height - 28) / 2
        width: Utils.Theme.isTop ? root.indicatorWidth : 28
        height: Utils.Theme.isSide ? root.indicatorHeight : 28
        radius: Utils.Theme.roundingFull
        color: Utils.Theme.accent
        visible: root.activeIndex >= 0

        Behavior on x {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutBack }
        }
        Behavior on y {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutBack }
        }
        Behavior on width {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
        }
    }

    GridLayout {
        id: layout

        flow: Utils.Theme.isSide ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: Utils.Theme.isTop ? -1 : 1
        rows: Utils.Theme.isSide ? -1 : 1
        columnSpacing: Utils.Theme.isTop ? Utils.Theme.spacingNormal : 0
        rowSpacing: Utils.Theme.isSide ? Utils.Theme.spacingNormal : 0
        z: 1

        states: [
            State {
                name: "side"
                when: Utils.Theme.isSide
                AnchorChanges {
                    target: layout
                    anchors.horizontalCenter: root.horizontalCenter
                    anchors.top: root.top
                }
                PropertyChanges {
                    layout.anchors.topMargin: Utils.Theme.spacingNormal
                }
            },
            State {
                name: "top"
                when: Utils.Theme.isTop
                AnchorChanges {
                    target: layout
                    anchors.verticalCenter: root.verticalCenter
                    anchors.left: root.left
                }
                PropertyChanges {
                    layout.anchors.leftMargin: Utils.Theme.spacingNormal
                }
            }
        ]

        Repeater {
            model: root.configuredIds.length

            Item {
                id: wsSlot

                required property int index
                readonly property int wsId: root.configuredIds[index]
                readonly property bool active: wsId === root.activeWsId
                readonly property bool occupied: root.occupiedIds[wsId] ?? false
                readonly property var icons: root.windowIcons[wsId] ?? []
                readonly property int contentSize: 28 + icons.length * 24

                // Entrance cascade
                property real _shift: root._wsAnimStep >= index ? 0 : 8
                Behavior on _shift {
                    NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                }
                opacity: root._wsAnimStep >= index ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                }
                transform: Translate {
                    x: Utils.Theme.isTop ? wsSlot._shift : 0
                    y: Utils.Theme.isSide ? wsSlot._shift : 0
                }

                Layout.alignment: Utils.Theme.isSide ? Qt.AlignHCenter : Qt.AlignVCenter
                Layout.preferredWidth: Utils.Theme.isTop ? contentSize : 28
                Layout.preferredHeight: Utils.Theme.isSide ? contentSize : 28

                Behavior on Layout.preferredHeight {
                    Utils.Anim {}
                }
                Behavior on Layout.preferredWidth {
                    Utils.Anim {}
                }

                // Content: dot + window icons, flow direction follows bar mode
                Grid {
                    id: wsContent

                    anchors.centerIn: parent
                    flow: Utils.Theme.isSide ? Grid.TopToBottom : Grid.LeftToRight
                    columns: Utils.Theme.isTop ? -1 : 1
                    rows: Utils.Theme.isSide ? -1 : 1
                    spacing: Utils.Theme.spacingTiny

                    // Workspace state icon
                    Item {
                        width: 28
                        height: 28

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1
                            text: wsSlot.occupied ? "󰮯" : "•"
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: wsSlot.active ? 14 : wsSlot.occupied ? 12 : 10
                            opacity: wsSlot.occupied ? 1 : (wsSlot.active ? 1 : 0.8)
                            scale: wsSlot.occupied ? 1 : (wsSlot.active ? 1.2 : 1)

                            Behavior on scale {
                                NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
                            }
                            color: wsSlot.active ? Utils.Theme.crust : wsSlot.occupied ? Utils.Theme.subtext0 : Utils.Theme.surface2

                            Behavior on font.pixelSize {
                                Utils.Anim {}
                            }
                            Behavior on color {
                                ColorAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
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
                            color: wsSlot.active ? Utils.Theme.crust : Utils.Theme.subtleText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: Utils.Theme.isTop ? 22 : 28
                            height: Utils.Theme.isSide ? 22 : 28

                            Behavior on color {
                                ColorAnimation { duration: Utils.Theme.animDurationSmall; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Hypr.dispatch("hl.dsp.focus({ workspace = " + wsSlot.wsId + " })")
                }
            }
        }
    }
}
