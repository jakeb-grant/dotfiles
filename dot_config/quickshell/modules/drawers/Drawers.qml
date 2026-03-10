pragma ComponentBehavior: Bound

import qs.modules.bar
import qs.modules.bar.popouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
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
            color: "transparent"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            mask: Region {
                // When popout is open on this screen: full window receives input
                // When closed: border + bar area receives input, rest is click-through
                x: popoutWrapper.active ? 0 : bar.implicitWidth
                y: popoutWrapper.active ? 0 : Utils.Theme.borderThickness
                width: popoutWrapper.active ? 0 : (win.width - bar.implicitWidth - Utils.Theme.borderThickness)
                height: popoutWrapper.active ? 0 : (win.height - Utils.Theme.borderThickness * 2)
                intersection: Intersection.Xor
            }

            HyprlandFocusGrab {
                id: focusGrab
                active: false
                windows: [win]
            }

            // Composited frame layer with shadow — border only (static, composites once)
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Utils.Theme.crust, 0.7)
                }

                Border {
                    bar: bar
                }
            }

            // Popout background — concave curves where popout meets bar and frame
            Shape {
                id: popoutBg

                readonly property real r: Utils.Theme.popoutRounding
                readonly property real pw: popoutWrapper.popoutWidth
                readonly property real ph: popoutWrapper.popoutHeight
                readonly property bool ft: popoutWrapper.flushTop
                readonly property bool fb: popoutWrapper.flushBottom
                // Left-side tab extensions (concave into bar)
                readonly property real topExt: ft ? 0 : r
                readonly property real btmExt: fb ? 0 : r
                // Right-side extension (concave fillet into frame when flush)
                readonly property real rightExt: (ft || fb) ? concaveR : 0
                // Concave curvature flattens as width shrinks
                readonly property real concaveR: Math.min(pw, r)
                // Convex rounding for normal corners
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

                    // Top-left: concave into bar, or square when flush top
                    PathArc {
                        x: popoutBg.ft ? 0 : popoutBg.concaveR
                        y: popoutBg.topExt
                        radiusX: popoutBg.concaveR
                        radiusY: popoutBg.r
                        direction: PathArc.Counterclockwise
                    }

                    // Top edge
                    PathLine {
                        x: popoutBg.pw - (popoutBg.ft ? 0 : popoutBg.convexR)
                        y: popoutBg.topExt
                    }

                    // Top-right: convex (normal) or square (flush top, for now)
                    PathArc {
                        x: popoutBg.pw
                        y: popoutBg.topExt + (popoutBg.ft ? 0 : popoutBg.convexR)
                        radiusX: popoutBg.ft ? 0 : popoutBg.convexR
                        radiusY: popoutBg.ft ? 0 : popoutBg.convexR
                    }

                    // Right edge — stop short when flush bottom for concave fillet
                    PathLine {
                        x: popoutBg.pw
                        y: popoutBg.fb
                            ? popoutBg.topExt + popoutBg.ph - popoutBg.concaveR
                            : popoutBg.topExt + popoutBg.ph - popoutBg.convexR
                    }

                    // Bottom-right: concave fillet into frame (flush) or convex (normal)
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

                    // Bottom edge
                    PathLine {
                        x: popoutBg.fb ? 0 : popoutBg.concaveR
                        y: popoutBg.topExt + popoutBg.ph
                    }

                    // Bottom-left: concave into bar, or square when flush bottom
                    PathArc {
                        x: 0
                        y: popoutBg.fb
                            ? popoutBg.topExt + popoutBg.ph
                            : popoutBg.height
                        radiusX: popoutBg.concaveR
                        radiusY: popoutBg.r
                        direction: PathArc.Counterclockwise
                    }

                    // Implicit close: left edge back to start
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
