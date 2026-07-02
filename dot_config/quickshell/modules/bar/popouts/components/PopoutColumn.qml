import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

// Base popout body: standard spacing plus a zero-height spacer that forces
// the popout's fixed content width. Children added by the popout land after
// the spacer.
ColumnLayout {
    id: root

    property real contentWidth: Utils.Theme.popoutWidth

    spacing: Utils.Theme.spacingNormal

    Item {
        implicitWidth: root.contentWidth
        implicitHeight: 0
    }
}
