pragma ComponentBehavior: Bound

import qs.modules.bar
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
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
                // Xor: border + bar area receives input, everything else is click-through
                x: bar.implicitWidth
                y: Utils.Theme.borderThickness
                width: win.width - bar.implicitWidth - Utils.Theme.borderThickness
                height: win.height - Utils.Theme.borderThickness * 2
                intersection: Intersection.Xor
            }

            HyprlandFocusGrab {
                id: focusGrab
                active: false
                windows: [win]
            }

            // Composited frame layer with shadow
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
        }
    }
}
