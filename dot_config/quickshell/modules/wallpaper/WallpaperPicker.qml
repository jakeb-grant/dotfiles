pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal
    focus: true

    // Entrance animation
    opacity: 0
    scale: 0.95
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation {
            duration: Utils.Theme.animDurationSmall
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Utils.Theme.animCurveStandard
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Utils.Theme.animDurationSmall
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Utils.Theme.animCurveStandard
        }
    }

    readonly property int _cols: 3

    Keys.onPressed: event => {
        const count = Services.Wallpaper.wallpapers.length;
        if (count === 0 && event.key !== Qt.Key_Escape) return;

        switch (event.key) {
        case Qt.Key_Escape:
            Services.Wallpaper.visible = false;
            event.accepted = true;
            break;
        case Qt.Key_Left:
            Services.Wallpaper.selectedIndex = Math.max(
                Services.Wallpaper.selectedIndex - 1, 0);
            event.accepted = true;
            break;
        case Qt.Key_Right:
            Services.Wallpaper.selectedIndex = Math.min(
                Services.Wallpaper.selectedIndex + 1, count - 1);
            event.accepted = true;
            break;
        case Qt.Key_Up:
            Services.Wallpaper.selectedIndex = Math.max(
                Services.Wallpaper.selectedIndex - root._cols, 0);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            Services.Wallpaper.selectedIndex = Math.min(
                Services.Wallpaper.selectedIndex + root._cols, count - 1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            const idx = Math.min(Services.Wallpaper.selectedIndex, count - 1);
            Services.Wallpaper.setWallpaper(Services.Wallpaper.wallpapers[idx]);
            event.accepted = true;
            break;
        }
    }

    // ── Header ──
    RowLayout {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "wallpaper"
            font.pixelSize: Utils.Theme.headerIconSize
            color: Utils.Theme.subtleText
        }

        Text {
            text: "Wallpapers"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
            Layout.fillWidth: true
        }

        Text {
            text: Utils.Theme.themeName
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.subtext0
        }

        Utils.MaterialIcon {
            text: "close"
            font.pixelSize: Utils.Theme.iconSize
            color: closeMouse.containsMouse ? Utils.Theme.text : Utils.Theme.subtext0

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -Utils.Theme.spacingNormal
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Wallpaper.visible = false
            }
        }
    }

    // ── Wallpaper grid ──
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(grid.implicitHeight,
            Utils.Theme.wallpaperPickerMaxHeight)
        clip: true
        contentHeight: grid.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: parent.contentHeight > parent.height
                ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 3
                radius: 2
                color: Utils.Theme.overlay0
                opacity: parent.active ? 0.8 : 0.4
                Behavior on opacity {
                    NumberAnimation { duration: Utils.Theme.animDurationFast }
                }
            }
        }

        GridLayout {
            id: grid
            width: parent.width
            columns: root._cols
            columnSpacing: Utils.Theme.spacingNormal
            rowSpacing: Utils.Theme.spacingNormal

            Repeater {
                model: Services.Wallpaper.wallpapers

                delegate: Rectangle {
                    id: thumb

                    required property int index
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16
                    radius: Utils.Theme.listItemRadius
                    color: Utils.Theme.surface0
                    clip: true

                    readonly property bool isSelected: index === Services.Wallpaper.selectedIndex
                    readonly property bool isCurrent: Services.Wallpaper.currentWallpaper === modelData

                    border.width: isCurrent ? 2 : isSelected ? 1 : 0
                    border.color: isCurrent ? Utils.Theme.accent
                        : isSelected ? Utils.Theme.overlay1 : "transparent"

                    Behavior on border.width {
                        NumberAnimation { duration: Utils.Theme.animDurationFast }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: thumb.border.width > 0 ? 2 : 0
                        source: "file://" + Services.Wallpaper.wallpaperDir + "/" + thumb.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(320, 180)
                    }

                    // Hover/selection overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Utils.Theme.hoverBg
                        opacity: thumbMouse.containsMouse || thumb.isSelected ? 0.5 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                        }
                    }

                    // Filename on hover or selection
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: nameLabel.implicitHeight + Utils.Theme.spacingSmall * 2
                        color: Utils.Theme.crust
                        opacity: 0.85
                        visible: thumbMouse.containsMouse || thumb.isSelected

                        Text {
                            id: nameLabel
                            anchors.centerIn: parent
                            text: thumb.modelData.replace(/\.[^.]+$/, "")
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.fontSizeXSmall
                            color: Utils.Theme.text
                            elide: Text.ElideMiddle
                            width: parent.width - Utils.Theme.spacingSmall * 2
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: thumbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Wallpaper.setWallpaper(thumb.modelData)
                        onContainsMouseChanged: {
                            if (containsMouse)
                                Services.Wallpaper.selectedIndex = thumb.index;
                        }
                    }
                }
            }
        }
    }

    // ── Empty state ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Utils.Theme.wallpaperPickerMaxHeight / 3
        visible: Services.Wallpaper.wallpapers.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Utils.Theme.spacingSmall

            Utils.MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "folder_open"
                font.pixelSize: Utils.Theme.headerIconSizeLarge
                color: Utils.Theme.disabledText
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No wallpapers for this theme"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.disabledText
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "~/.config/wallpapers/" + Services.Wallpaper.paletteSlug + "/"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeXSmall
                color: Utils.Theme.subtleText
            }
        }
    }

    Connections {
        target: Services.Wallpaper
        function onVisibleChanged(): void {
            if (Services.Wallpaper.visible) {
                root.forceActiveFocus();
                root.opacity = 1;
                root.scale = 1;
            } else {
                root.opacity = 0;
                root.scale = 0.95;
            }
        }
    }
}
