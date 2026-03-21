import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.utils as Utils

Scope {
    id: root

    required property ShellScreen screen
    required property Item bar

    // Left edge: bar width (side mode) or border thickness
    ExclusionZone {
        anchors.left: true
        exclusiveZone: Utils.Theme.isSide ? root.bar.exclusiveZone : (Utils.Theme.borderThickness > 0 ? Utils.Theme.borderThickness : 0)
        visible: Utils.Theme.isSide || Utils.Theme.borderThickness > 0
    }

    // Top edge: bar height (top mode) or border thickness
    ExclusionZone {
        anchors.top: true
        exclusiveZone: Utils.Theme.isTop ? root.bar.exclusiveZone : (Utils.Theme.borderThickness > 0 ? Utils.Theme.borderThickness : 0)
        visible: Utils.Theme.isTop || Utils.Theme.borderThickness > 0
    }

    // Right edge: border thickness
    ExclusionZone {
        anchors.right: true
        visible: Utils.Theme.borderThickness > 0
        exclusiveZone: Utils.Theme.borderThickness > 0 ? Utils.Theme.borderThickness : 0
    }

    // Bottom edge: border thickness
    ExclusionZone {
        anchors.bottom: true
        visible: Utils.Theme.borderThickness > 0
        exclusiveZone: Utils.Theme.borderThickness > 0 ? Utils.Theme.borderThickness : 0
    }

    component ExclusionZone: PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "quickshell-exclusion"
        WlrLayershell.layer: WlrLayer.Top
        color: "transparent"
        exclusiveZone: Utils.Theme.borderThickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
