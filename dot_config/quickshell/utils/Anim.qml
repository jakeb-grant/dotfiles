import QtQuick
import qs.utils as Utils

NumberAnimation {
    duration: Utils.Theme.animDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Utils.Theme.animCurveStandard
}
