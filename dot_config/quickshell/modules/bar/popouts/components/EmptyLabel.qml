import QtQuick
import qs.utils as Utils

// Italic muted empty-state text ("No networks found", "Scanning...", ...)
Text {
    font.family: Utils.Theme.fontFamily
    font.pixelSize: Utils.Theme.fontSizeSmall
    font.italic: true
    color: Utils.Theme.subtleText
}
