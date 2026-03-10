import QtQuick
import qs.utils as Utils

Text {
    id: root

    property real fill: 0
    property int grade: -25

    font.family: Utils.Theme.iconFontFamily
    font.pixelSize: Utils.Theme.iconSize
    font.variableAxes: ({
        FILL: root.fill.toFixed(1),
        GRAD: root.grade,
        opsz: fontInfo.pixelSize,
        wght: fontInfo.weight
    })

    Behavior on fill {
        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
    }
}
