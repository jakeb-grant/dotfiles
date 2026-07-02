import QtQuick
import qs.utils as Utils

// Fixed-height clipped list with a centered empty-state label.
// Callers set Layout.fillWidth: true; delegates size with ListView.view.width.
Item {
    id: root

    property alias model: list.model
    property alias delegate: list.delegate
    property alias count: list.count
    property string emptyText: ""

    implicitHeight: Utils.Theme.popoutListHeight
    clip: true

    ListView {
        id: list
        anchors.fill: parent
        spacing: Utils.Theme.spacingTiny
    }

    EmptyLabel {
        visible: list.count === 0
        anchors.centerIn: parent
        text: root.emptyText
    }
}
