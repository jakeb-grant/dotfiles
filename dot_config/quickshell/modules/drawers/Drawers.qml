pragma ComponentBehavior: Bound

import qs.modules.bar
import qs.modules.bar.popouts
import qs.modules.launcher
import qs.modules.notifications
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
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
            WlrLayershell.keyboardFocus: Services.Launcher.visible
                && Services.Launcher.activeScreen === scope.modelData.name
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            mask: Region {
                id: maskRegion
                // When popout or notification center is open: full window receives input
                // When closed: border + bar area receives input, rest is click-through
                readonly property int bt: Utils.Theme.borderThickness
                readonly property bool passthrough: !popoutWrapper.active
                    && !Services.Notifications.expanded
                    && !Services.Launcher.visible
                x: passthrough ? bar.implicitWidth : 0
                y: passthrough ? bt : 0
                width: passthrough ? (win.width - bar.implicitWidth - bt) : 0
                height: passthrough ? (win.height - bt * 2) : 0
                intersection: Intersection.Xor

                // Cut notification area out of the click-through zone
                Region {
                    x: notifBg.x
                    y: notifBg.y
                    width: (notifBg.visible && maskRegion.passthrough) ? notifBg.width : 0
                    height: (notifBg.visible && maskRegion.passthrough) ? notifBg.height : 0
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

            HyprlandFocusGrab {
                id: focusGrab
                active: Services.Notifications.expanded
                windows: [win]
                onCleared: Services.Notifications.expanded = false
            }

            // Click-outside-to-close for launcher
            MouseArea {
                anchors.fill: parent
                visible: Services.Launcher.visible
                onClicked: Services.Launcher.visible = false
                z: 0
            }


            // Composited frame + popout + notification layer — single shadow for
            // combined silhouette. NOTE: layer.enabled forces GPU offscreen rendering
            // every frame during animation. If sluggish on older GPUs, try reducing
            // frameShadowBlur or disabling shadowEnabled.
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowOpacity: Utils.Theme.frameShadowOpacity
                    blurMax: Utils.Theme.frameShadowBlur
                    shadowColor: Utils.Theme.frameShadow
                    autoPaddingEnabled: true
                }

                Border {
                    bar: bar
                }

                // Popout background — concave curves where popout meets bar and frame
                Shape {
                    id: popoutBg

                    readonly property real r: Utils.Theme.popoutRounding
                    readonly property real pw: popoutWrapper.popoutWidth
                    readonly property real ph: popoutWrapper.popoutHeight
                    readonly property bool ft: popoutWrapper.flushTop
                    readonly property bool fb: popoutWrapper.flushBottom
                    readonly property real topExt: ft ? 0 : r
                    readonly property real btmExt: fb ? 0 : r
                    readonly property real rightExt: (ft || fb) ? concaveR : 0
                    readonly property real concaveR: Math.min(pw, r)
                    readonly property real convexR: Math.min(pw / 2, r)

                    x: popoutWrapper.popoutX
                    y: popoutWrapper.popoutY - topExt
                    width: pw + rightExt
                    height: ph + topExt + btmExt
                    visible: pw > 1
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Utils.Theme.mantle

                        startX: 0
                        startY: 0

                        PathArc {
                            x: popoutBg.ft ? 0 : popoutBg.concaveR
                            y: popoutBg.topExt
                            radiusX: popoutBg.concaveR
                            radiusY: popoutBg.r
                            direction: PathArc.Counterclockwise
                        }

                        PathLine {
                            x: popoutBg.ft
                                ? popoutBg.pw + popoutBg.concaveR
                                : popoutBg.pw - popoutBg.convexR
                            y: popoutBg.topExt
                        }

                        PathArc {
                            x: popoutBg.pw
                            y: popoutBg.topExt + (popoutBg.ft ? popoutBg.concaveR : popoutBg.convexR)
                            radiusX: popoutBg.ft ? popoutBg.concaveR : popoutBg.convexR
                            radiusY: popoutBg.ft ? popoutBg.concaveR : popoutBg.convexR
                            direction: popoutBg.ft
                                ? PathArc.Counterclockwise
                                : PathArc.Clockwise
                        }

                        PathLine {
                            x: popoutBg.pw
                            y: popoutBg.fb
                                ? popoutBg.topExt + popoutBg.ph - popoutBg.concaveR
                                : popoutBg.topExt + popoutBg.ph - popoutBg.convexR
                        }

                        PathArc {
                            x: popoutBg.fb
                                ? popoutBg.pw + popoutBg.concaveR
                                : popoutBg.pw - popoutBg.convexR
                            y: popoutBg.topExt + popoutBg.ph
                            radiusX: popoutBg.fb ? popoutBg.concaveR : popoutBg.convexR
                            radiusY: popoutBg.fb ? popoutBg.concaveR : popoutBg.convexR
                            direction: popoutBg.fb
                                ? PathArc.Counterclockwise
                                : PathArc.Clockwise
                        }

                        PathLine {
                            x: popoutBg.fb ? 0 : popoutBg.concaveR
                            y: popoutBg.topExt + popoutBg.ph
                        }

                        PathArc {
                            x: 0
                            y: popoutBg.fb
                                ? popoutBg.topExt + popoutBg.ph
                                : popoutBg.height
                            radiusX: popoutBg.concaveR
                            radiusY: popoutBg.r
                            direction: PathArc.Counterclockwise
                        }
                    }
                }

                // Notification background — concave curves where notifications
                // meet the top and right frame edges
                Shape {
                    id: notifBg

                    readonly property real r: Utils.Theme.popoutRounding
                    readonly property int bt: Utils.Theme.borderThickness
                    readonly property int spacing: Utils.Theme.spacingNormal
                    readonly property real nw: Utils.Theme.notificationWidth + spacing * 2
                    readonly property real concaveR: Math.min(nw, r)
                    readonly property real convexR: Math.min(nw / 2, r)

                    property real animatedHeight: notifColumn.implicitHeight > 0
                        ? notifColumn.implicitHeight + spacing * 2 : 0
                    Behavior on animatedHeight {
                        NumberAnimation {
                            duration: Utils.Theme.animDurationSmall
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Utils.Theme.animCurveStandard
                        }
                    }

                    readonly property real nh: animatedHeight
                    // Extensions scale with nh so curves grow from nothing
                    // (mirrors popout's concaveR = Math.min(pw, r) pattern)
                    readonly property real leftExt: Math.min(nh, r)
                    readonly property real bottomExt: Math.min(nh, r)
                    // Clamp radii to prevent degenerate geometry at small heights
                    readonly property real cr: Math.min(concaveR, nh)
                    readonly property real cvr: Math.min(convexR, nh / 3)

                    x: win.width - bt - nw - leftExt
                    y: bt
                    width: nw + leftExt
                    height: nh + bottomExt
                    visible: nh > 1
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Utils.Theme.mantle

                        startX: 0
                        startY: 0

                        // Along top bezel to right edge
                        PathLine { x: notifBg.width; y: 0 }

                        // Down right bezel
                        PathLine { x: notifBg.width; y: notifBg.height }

                        // Bottom-right concave arc — right bezel to notification bottom
                        PathArc {
                            x: notifBg.width - notifBg.bottomExt
                            y: notifBg.nh
                            radiusX: notifBg.bottomExt
                            radiusY: notifBg.bottomExt
                            direction: PathArc.Counterclockwise
                        }

                        // Along notification bottom
                        PathLine {
                            x: notifBg.leftExt + notifBg.cvr
                            y: notifBg.nh
                        }

                        // Bottom-left convex corner
                        PathArc {
                            x: notifBg.leftExt
                            y: notifBg.nh - notifBg.cvr
                            radiusX: notifBg.cvr
                            radiusY: notifBg.cvr
                            direction: PathArc.Clockwise
                        }

                        // Up notification left edge
                        PathLine {
                            x: notifBg.leftExt
                            y: notifBg.cr
                        }

                        // Top-left concave arc — notification left to top bezel
                        PathArc {
                            x: 0
                            y: 0
                            radiusX: notifBg.leftExt
                            radiusY: notifBg.cr
                            direction: PathArc.Counterclockwise
                        }
                    }
                }

                // Launcher background — concave curves where launcher meets bottom bezel
                Shape {
                    id: launcherBg

                    readonly property real r: Utils.Theme.popoutRounding
                    readonly property int bt: Utils.Theme.borderThickness
                    readonly property int spacing: Utils.Theme.spacingNormal
                    readonly property real lw: Utils.Theme.launcherWidth + spacing * 2
                    readonly property real concaveR: Math.min(lw, r)
                    readonly property real convexR: Math.min(lw / 2, r)

                    property real animatedHeight: launcherPanel.visible
                        ? launcherPanel.implicitHeight + spacing * 2 : 0
                    Behavior on animatedHeight {
                        NumberAnimation {
                            duration: Utils.Theme.animDurationSmall
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Utils.Theme.animCurveStandard
                        }
                    }

                    readonly property real lh: animatedHeight
                    readonly property real leftExt: Math.min(lh, r)
                    readonly property real rightExt: Math.min(lh, r)
                    readonly property real topExt: Math.min(lh, r)
                    readonly property real cr: Math.min(concaveR, lh)
                    readonly property real cvr: Math.min(convexR, lh / 3)

                    x: (win.width - lw) / 2 - leftExt
                    y: win.height - bt - lh - topExt
                    width: lw + leftExt + rightExt
                    height: lh + topExt
                    visible: lh > 1
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Utils.Theme.mantle

                        // Start at top-left of the shape
                        startX: launcherBg.leftExt
                        startY: launcherBg.cvr

                        // Top-left convex arc
                        PathArc {
                            x: launcherBg.leftExt + launcherBg.cvr
                            y: 0
                            radiusX: launcherBg.cvr
                            radiusY: launcherBg.cvr
                            direction: PathArc.Clockwise
                        }

                        // Along top
                        PathLine {
                            x: launcherBg.width - launcherBg.rightExt - launcherBg.cvr
                            y: 0
                        }

                        // Top-right convex arc
                        PathArc {
                            x: launcherBg.width - launcherBg.rightExt
                            y: launcherBg.cvr
                            radiusX: launcherBg.cvr
                            radiusY: launcherBg.cvr
                            direction: PathArc.Clockwise
                        }

                        // Down right edge
                        PathLine {
                            x: launcherBg.width - launcherBg.rightExt
                            y: launcherBg.topExt + launcherBg.lh - launcherBg.cr
                        }

                        // Bottom-right concave arc (into bottom bezel)
                        PathArc {
                            x: launcherBg.width
                            y: launcherBg.height
                            radiusX: launcherBg.rightExt
                            radiusY: launcherBg.cr
                            direction: PathArc.Counterclockwise
                        }

                        // Along bottom bezel
                        PathLine { x: 0; y: launcherBg.height }

                        // Bottom-left concave arc (from bezel up)
                        PathArc {
                            x: launcherBg.leftExt
                            y: launcherBg.topExt + launcherBg.lh - launcherBg.cr
                            radiusX: launcherBg.leftExt
                            radiusY: launcherBg.cr
                            direction: PathArc.Counterclockwise
                        }
                    }
                }
            }

            // Launcher panel — positioned at bottom center over the Shape
            LauncherPanel {
                id: launcherPanel
                x: (win.width - Utils.Theme.launcherWidth) / 2
                y: win.height - Utils.Theme.borderThickness
                    - Utils.Theme.spacingNormal - implicitHeight
                width: Utils.Theme.launcherWidth
                visible: Services.Launcher.visible
                    && Services.Launcher.activeScreen === scope.modelData.name
            }

            // Notification cards — positioned in top-right corner over the Shape
            ColumnLayout {
                id: notifColumn

                readonly property bool expanded: Services.Notifications.expanded

                x: win.width - Utils.Theme.borderThickness
                    - Utils.Theme.notificationWidth - Utils.Theme.spacingNormal
                y: Utils.Theme.borderThickness + Utils.Theme.spacingNormal
                width: Utils.Theme.notificationWidth
                spacing: Utils.Theme.spacingSmall

                // ── Header (expanded only) ──
                RowLayout {
                    visible: notifColumn.expanded
                    Layout.fillWidth: true
                    Layout.bottomMargin: Utils.Theme.spacingSmall

                    Text {
                        text: "Notifications"
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.headerFontSize
                        font.bold: true
                        color: Utils.Theme.text
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: clearLabel.implicitWidth + Utils.Theme.spacingNormal * 2
                        height: Utils.Theme.pillHeight
                        radius: Utils.Theme.roundingFull
                        color: clearMouse.containsMouse
                            ? Utils.Theme.hoverBg : Utils.Theme.surface1

                        Behavior on color {
                            ColorAnimation { duration: Utils.Theme.animDurationFast }
                        }

                        Text {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear all"
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.pillFontSize
                            color: Utils.Theme.text
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Notifications.clearHistory()
                        }
                    }
                }

                // ── Scrollable notification list ──
                Flickable {
                    id: notifFlick

                    Layout.fillWidth: true
                    Layout.preferredHeight: notifColumn.expanded
                        ? Math.min(notifCards.implicitHeight,
                            Utils.Theme.notificationCenterMaxHeight)
                        : notifCards.implicitHeight
                    clip: notifColumn.expanded
                    interactive: notifColumn.expanded
                    contentHeight: notifCards.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: notifCards
                        width: notifFlick.width
                        spacing: Utils.Theme.spacingNormal

                        Repeater {
                            model: notifColumn.expanded
                                ? Services.Notifications.history
                                : Services.Notifications.popups

                            delegate: NotificationCard {
                                required property Notification modelData
                                notification: modelData
                                historyMode: notifColumn.expanded
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // ── Expand button (collapsed only) ──
                Item {
                    visible: !notifColumn.expanded
                        && Services.Notifications.count > 0
                        && Services.Notifications.historyCount
                            > Services.Notifications.count
                    Layout.fillWidth: true
                    Layout.preferredHeight: Utils.Theme.pillHeight

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Utils.Theme.spacingSmall

                        Utils.MaterialIcon {
                            text: "expand_more"
                            font.pixelSize: Utils.Theme.iconSizeSmall
                            color: Utils.Theme.subtext0
                        }

                        Text {
                            text: (Services.Notifications.historyCount
                                - Services.Notifications.count) + " more"
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.fontSizeSmall
                            color: Utils.Theme.subtext0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Notifications.toggleExpanded()
                    }
                }
            }

            PersistentProperties {
                id: visibilities
                property bool bar: true
            }

            BarWrapper {
                id: bar

                anchors.top: parent.top
                anchors.bottom: parent.bottom

                screen: scope.modelData
            }

            PopoutWrapper {
                id: popoutWrapper
                barWidth: bar.implicitWidth
                screen: scope.modelData
            }
        }
    }
}
