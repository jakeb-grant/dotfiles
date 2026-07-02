import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

// Section label row with an optional spinning refresh button.
// Extra trailing actions (e.g. a power toggle) can be added as children —
// they land after the refresh button.
RowLayout {
    id: root

    property string title
    property bool showRefresh: false
    property bool spinning: false

    signal refreshClicked()

    spacing: Utils.Theme.spacingNormal

    onSpinningChanged: if (!spinning) refreshButton.rotation = 0

    SectionLabel {
        text: root.title
        Layout.fillWidth: true
    }

    IconButton {
        id: refreshButton
        visible: root.showRefresh
        text: "refresh"
        font.pixelSize: Utils.Theme.headerActionIconSize
        onClicked: root.refreshClicked()

        RotationAnimation on rotation {
            running: root.spinning
            from: 0
            to: 360
            duration: Utils.Theme.animDurationSpin
            loops: Animation.Infinite
        }
    }
}
