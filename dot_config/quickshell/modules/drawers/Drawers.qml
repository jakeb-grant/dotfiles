pragma ComponentBehavior: Bound

import qs.modules.bar
import qs.modules.bar.popouts
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services as Services
import qs.utils as Utils

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: bar
        }

        PanelWindow {
            id: win

            screen: scope.modelData
            WlrLayershell.namespace: "quickshell-drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: (Services.Launcher.visible
                    && Services.Launcher.activeScreen === scope.modelData)
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            mask: Region {
                id: maskRegion
                // When popout/notification/launcher is open: full window receives input.
                // When closed: bar reserves a strip of width barMargin*2 + barWidth and
                // height barMargin*2 + bar dimension; rest is click-through.
                readonly property int barReserve: Utils.Theme.barMargin * 2 + Utils.Theme.barWidth
                readonly property bool passthrough: !popoutWrapper.active
                    && !Services.Launcher.visible
                x: passthrough
                    ? (Utils.Theme.isSide ? barReserve : 0)
                    : 0
                y: passthrough
                    ? (Utils.Theme.isTop ? barReserve : 0)
                    : 0
                width: passthrough
                    ? (Utils.Theme.isSide ? (win.width - barReserve) : win.width)
                    : 0
                height: passthrough
                    ? (Utils.Theme.isTop ? (win.height - barReserve) : win.height)
                    : 0
                intersection: Intersection.Xor

                // Cut notification area out of the click-through zone
                Region {
                    x: notifColumn.x
                    y: notifColumn.y
                    width: (notifColumn.implicitHeight > 0 && maskRegion.passthrough) ? notifColumn.width : 0
                    height: (notifColumn.implicitHeight > 0 && maskRegion.passthrough) ? notifColumn.implicitHeight : 0
                    intersection: Intersection.Subtract
                }

                // Cut launcher area out of the click-through zone
                Region {
                    x: launcherBg.x
                    y: launcherBg.y
                    width: (launcherBg.visible && maskRegion.passthrough) ? launcherBg.width : 0
                    height: (launcherBg.visible && maskRegion.passthrough) ? launcherBg.height : 0
                    intersection: Intersection.Subtract
                }


            }

            // Click-outside-to-close for launcher
            MouseArea {
                anchors.fill: parent
                visible: Services.Launcher.visible
                onClicked: Services.Launcher.visible = false
                z: 0
            }


            // Launcher floating island
            Rectangle {
                id: launcherBg

                readonly property int spacing: Utils.Theme.spacingNormal
                readonly property real launcherActiveWidth: Services.Launcher.submenu === "wallpaper"
                    ? Utils.Theme.wallpaperPickerWidth : Utils.Theme.launcherWidth
                readonly property real lw: launcherActiveWidth + spacing * 2

                property real animatedHeight: launcherPanel.visible
                    ? launcherPanel.implicitHeight + spacing * 2 : 0
                Behavior on animatedHeight {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }
                }

                readonly property real lh: animatedHeight

                // x derives from the *animated* width so the island stays centered
                // during the wallpaper-picker width morph. Binding to lw (instant)
                // would snap x and grow the island from its left edge.
                x: (win.width - width) / 2
                y: win.height - lh - Utils.Theme.barMargin
                width: lw
                height: lh
                visible: lh > 1
                color: Utils.Theme.launcherBg
                radius: Utils.Theme.islandRounding

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }
                }

                layer.enabled: visible
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
            }

            // Launcher panel — positioned inside the floating launcher island
            LauncherPanel {
                id: launcherPanel
                x: launcherBg.x + launcherBg.spacing
                y: launcherBg.y + launcherBg.spacing
                width: launcherBg.launcherActiveWidth
                visible: Services.Launcher.visible
                    && Services.Launcher.activeScreen === scope.modelData

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
                }
            }

            // Notification cards — each card is its own floating island
            // (drop shadow lives on the NotificationCard itself).
            ColumnLayout {
                id: notifColumn

                x: win.width - Utils.Theme.notificationWidth - Utils.Theme.barMargin
                y: Utils.Theme.isTop
                    ? (Utils.Theme.barMargin + Utils.Theme.barWidth + Utils.Theme.islandGap)
                    : Utils.Theme.barMargin
                width: Utils.Theme.notificationWidth
                spacing: Utils.Theme.islandGap

                Repeater {
                    model: Services.Notifications.popups

                    delegate: NotificationCard {
                        required property Notification modelData
                        Layout.fillWidth: true
                        notification: modelData
                    }
                }
            }

            BarWrapper {
                id: bar

                screen: scope.modelData

                readonly property bool monitorFullscreen: {
                    const mon = Services.Hypr.monitorFor(scope.modelData);
                    const ws = mon?.activeWorkspace;
                    if (!ws) return false;
                    if (ws.hasFullscreen !== undefined) return ws.hasFullscreen;
                    return ws.lastIpcObject?.hasfullscreen ?? false;
                }

                opacity: monitorFullscreen ? 0 : 1
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation { duration: Utils.Theme.animDuration; easing.type: Easing.OutCubic }
                }

                x: Utils.Theme.barMargin
                y: Utils.Theme.barMargin
                width: Utils.Theme.isSide
                    ? Utils.Theme.barWidth
                    : (parent.width - 2 * Utils.Theme.barMargin)
                height: Utils.Theme.isTop
                    ? Utils.Theme.barWidth
                    : (parent.height - 2 * Utils.Theme.barMargin)
            }

            PopoutWrapper {
                id: popoutWrapper
                barWidth: Utils.Theme.isSide ? bar.implicitWidth : 0
                barHeight: Utils.Theme.isTop ? bar.implicitHeight : 0
                screen: scope.modelData
            }
        }

        // The OSD gets its own overlay-layer window: Hyprland renders
        // fullscreen windows above the Top layer the drawers window lives on,
        // and volume keys during fullscreen video are the OSD's prime
        // scenario. The empty input mask keeps it fully click-through. The
        // window stays mapped permanently — mapping on demand races the
        // compositor's configure (the surface maps 0×0 and can miss its size
        // for the whole 1.4s display window); an idle transparent overlay
        // surface costs nothing.
        PanelWindow {
            id: osdWin

            screen: scope.modelData
            WlrLayershell.namespace: "quickshell-osd"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            anchors.bottom: true
            margins.bottom: 96
            // Oversize for the drop shadow's bleed beyond the island bounds
            implicitWidth: osd.implicitWidth + Utils.Theme.islandShadowBlur * 2
            implicitHeight: osd.implicitHeight + Utils.Theme.islandShadowBlur * 2

            mask: Region {}

            OsdOverlay {
                id: osd
                anchors.centerIn: parent
            }
        }
    }
}
