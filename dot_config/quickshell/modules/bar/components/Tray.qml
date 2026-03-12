pragma ComponentBehavior: Bound

import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

Rectangle {
    id: root

    implicitWidth: Utils.Theme.barInnerWidth
    implicitHeight: col.implicitHeight + Utils.Theme.spacingNormal * 2
    radius: Utils.Theme.roundingNormal
    color: Utils.Theme.pillBg
    visible: SystemTray.items.count > 0

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: Utils.Theme.spacingSmall

        Repeater {
            model: SystemTray.items

            TrayItem {
                required property SystemTrayItem modelData
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
