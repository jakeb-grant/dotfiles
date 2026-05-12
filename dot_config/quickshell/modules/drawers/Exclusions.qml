import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.utils as Utils

Scope {
    id: root

    required property ShellScreen screen
    required property Item bar

    // Single exclusion zone — keeps the floating bar from being slid under by
    // tiled clients. exclusiveZone already includes barMargin (see BarWrapper).
    PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "quickshell-exclusion"
        WlrLayershell.layer: WlrLayer.Top
        color: "transparent"
        anchors.left: Utils.Theme.isSide
        anchors.top: Utils.Theme.isTop
        exclusiveZone: root.bar.exclusiveZone
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
