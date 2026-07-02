import QtQuick
import qs.utils as Utils

// Small muted section label ("Networks", "Output", "Hardware", ...)
Text {
    font.family: Utils.Theme.fontFamily
    font.pixelSize: Utils.Theme.fontSizeSmall
    font.weight: Font.Medium
    color: Utils.Theme.subtext0
}
