pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: Utils.Theme.popoutWidth
        implicitHeight: 0
    }

    // Scan palette directory for available themes
    property var themes: []

    Component.onCompleted: scanProc.running = true

    Process {
        id: scanProc
        command: ["sh", "-c", `for f in ${Utils.Theme.palettePath}/*.json; do [ "$(basename "$f")" = "active.json" ] && continue; name=$(sed -n 's/.*"_name".*: *"\\(.*\\)".*/\\1/p' "$f" 2>/dev/null); [ -n "$name" ] && echo "$(basename "$f")|$name"; done | sort`]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                if (parts.length === 2)
                    root.themes = [...root.themes, { file: parts[0], name: parts[1] }];
            }
        }
    }

    Process {
        id: switchProc
        property string targetFile: ""
        command: ["cp", Utils.Theme.palettePath + "/" + targetFile, Utils.Theme.palettePath + "/active.json"]
    }

    // Header
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "palette"
            font.pixelSize: Utils.Theme.headerIconSize
            color: Utils.Theme.mauve
        }

        Text {
            text: "Theme"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
        }
    }

    // Current theme name
    Text {
        text: Utils.Theme.themeName
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtext0
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
    }

    // Theme list
    Column {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingTiny

        Repeater {
            model: root.themes

            Rectangle {
                id: themeItem

                required property var modelData
                required property int index

                readonly property bool isCurrent: modelData.name === Utils.Theme.themeName

                width: parent?.width ?? 0
                height: Utils.Theme.actionItemHeight
                radius: Utils.Theme.listItemRadius
                color: "transparent"

                // Hover background
                Rectangle {
                    anchors.fill: parent
                    radius: Utils.Theme.listItemRadius
                    color: Utils.Theme.hoverBg
                    opacity: !themeItem.isCurrent && themeMouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Utils.Theme.listItemMargin
                    anchors.rightMargin: Utils.Theme.listItemMargin
                    spacing: Utils.Theme.spacingNormal

                    Utils.MaterialIcon {
                        text: themeItem.isCurrent ? "radio_button_checked" : "radio_button_unchecked"
                        font.pixelSize: Utils.Theme.headerFontSize
                        color: themeItem.isCurrent ? Utils.Theme.mauve : Utils.Theme.subtleText
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        text: themeItem.modelData.name
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.fontSize
                        font.weight: themeItem.isCurrent ? Font.Medium : Font.Normal
                        color: themeItem.isCurrent ? Utils.Theme.text : Utils.Theme.subtext0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                        }
                    }
                }

                MouseArea {
                    id: themeMouse
                    anchors.fill: parent
                    hoverEnabled: !themeItem.isCurrent
                    cursorShape: themeItem.isCurrent ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !themeItem.isCurrent
                    onClicked: {
                        switchProc.targetFile = themeItem.modelData.file;
                        switchProc.running = true;
                    }
                }
            }
        }
    }

    // Empty state
    Text {
        visible: root.themes.length === 0
        text: "No themes found"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        font.italic: true
        color: Utils.Theme.disabledText
        Layout.alignment: Qt.AlignHCenter
    }
}
