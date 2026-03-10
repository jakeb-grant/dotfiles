pragma ComponentBehavior: Bound

import qs.modules.bar
import qs.modules.bar.popouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
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

            // Popout background — per-corner radii based on edge clamping
            Rectangle {
                x: popoutWrapper.popoutX
                y: popoutWrapper.popoutY
                width: popoutWrapper.popoutWidth
                height: popoutWrapper.popoutHeight
                visible: popoutWrapper.popoutWidth > 0
                color: Utils.Theme.mantle
                // Left corners always square (flush with bar)
                topLeftRadius: 0
                bottomLeftRadius: 0
                // Right corners square when flush with border frame
                topRightRadius: popoutWrapper.flushTop ? 0 : Utils.Theme.borderRounding
                bottomRightRadius: popoutWrapper.flushBottom ? 0 : Utils.Theme.borderRounding
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
