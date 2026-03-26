pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingSmall

    readonly property int bandHeight: 120
    readonly property int cellWidth: 200
    readonly property int slant: 30

    // Filter: "all" | "singles" | "sets"
    property string filter: "all"

    readonly property var filteredEntries: {
        const all = Services.Wallpaper.entries;
        if (filter === "all") return all;
        const wantSet = filter === "sets";
        const result = [];
        for (let i = 0; i < all.length; i++) {
            if (all[i].isSet === wantSet) result.push(all[i]);
        }
        return result;
    }

    readonly property int singlesCount: {
        const all = Services.Wallpaper.entries;
        let n = 0;
        for (let i = 0; i < all.length; i++) if (!all[i].isSet) n++;
        return n;
    }

    readonly property int setsCount: {
        const all = Services.Wallpaper.entries;
        let n = 0;
        for (let i = 0; i < all.length; i++) if (all[i].isSet) n++;
        return n;
    }

    Keys.onPressed: event => {
        const count = root.filteredEntries.length;
        if (count === 0 && event.key !== Qt.Key_Escape) return;

        switch (event.key) {
        case Qt.Key_Escape:
            if (!Services.Launcher.goBack())
                Services.Launcher.visible = false;
            event.accepted = true;
            break;
        case Qt.Key_Left:
            Services.Wallpaper.selectedIndex = Math.max(
                Services.Wallpaper.selectedIndex - 1, 0);
            bandFlick.ensureVisible(Services.Wallpaper.selectedIndex);
            event.accepted = true;
            break;
        case Qt.Key_Right:
        case Qt.Key_Tab:
            Services.Wallpaper.selectedIndex = Math.min(
                Services.Wallpaper.selectedIndex + 1, count - 1);
            bandFlick.ensureVisible(Services.Wallpaper.selectedIndex);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            const idx = Math.min(Services.Wallpaper.selectedIndex, count - 1);
            if (idx >= 0)
                Services.Wallpaper.applyEntry(root.filteredEntries[idx]);
            event.accepted = true;
            break;
        }
    }

    // ── Header row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "arrow_back"
            font.pixelSize: Utils.Theme.iconSize
            color: backMouse.containsMouse ? Utils.Theme.text : Utils.Theme.subtext0

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                anchors.margins: -Utils.Theme.spacingSmall
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Launcher.goBack()
            }
        }

        Utils.MaterialIcon {
            text: "wallpaper"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtleText
        }

        Text {
            text: "Wallpapers"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSize
            font.bold: true
            color: Utils.Theme.text
        }

        Item { Layout.fillWidth: true }

        // ── Filter pills ──
        Row {
            spacing: 2

            Repeater {
                model: [
                    { key: "all", label: "All", count: Services.Wallpaper.entries.length },
                    { key: "singles", label: "Singles", count: root.singlesCount },
                    { key: "sets", label: "Sets", count: root.setsCount }
                ]

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool active: root.filter === modelData.key
                    readonly property bool hovered: pillMouse.containsMouse

                    width: pillLabel.implicitWidth + Utils.Theme.spacingNormal * 2
                    height: pillLabel.implicitHeight + Utils.Theme.spacingSmall
                    radius: height / 2
                    color: active ? Utils.Theme.accent : (hovered ? Utils.Theme.surface1 : Utils.Theme.surface0)
                    visible: modelData.count > 0 || modelData.key === "all"

                    Behavior on color {
                        ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                    }

                    Text {
                        id: pillLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Utils.Theme.fontFamily
                        font.pixelSize: Utils.Theme.fontSizeXSmall
                        font.bold: active
                        color: active ? Utils.Theme.crust : (hovered ? Utils.Theme.text : Utils.Theme.subtext0)

                        Behavior on color {
                            ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.filter = modelData.key;
                            Services.Wallpaper.selectedIndex = 0;
                            bandScrollBehavior.enabled = false;
                            bandFlick.contentX = 0;
                            bandScrollBehavior.enabled = true;
                        }
                    }
                }
            }
        }

        Text {
            text: Utils.Theme.themeName
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeXSmall
            color: Utils.Theme.subtext0
        }
    }

    // ── Wallpaper band ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.bandHeight
        radius: Utils.Theme.listItemRadius
        color: Utils.Theme.surface0
        clip: true
        visible: root.filteredEntries.length > 0

        Flickable {
            id: bandFlick
            anchors.fill: parent
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: {
                const count = root.filteredEntries.length;
                return count > 0 ? count * (root.cellWidth - root.slant) + root.slant : 0;
            }
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentX {
                id: bandScrollBehavior
                enabled: true
                NumberAnimation {
                    duration: Utils.Theme.animDurationFast
                    easing.type: Easing.OutCubic
                }
            }

            function ensureVisible(idx: int): void {
                const step = root.cellWidth - root.slant;
                const itemX = idx * step;
                const itemRight = itemX + root.cellWidth;
                if (itemX < contentX)
                    contentX = itemX;
                else if (itemRight > contentX + width)
                    contentX = itemRight - width;
            }

            Item {
                id: bandRow
                width: bandFlick.contentWidth
                height: root.bandHeight

                Repeater {
                    model: root.filteredEntries.length

                    delegate: Item {
                        id: cell

                        required property int index

                        readonly property var entry: root.filteredEntries[index]
                        readonly property string entryName: entry ? entry.name : ""
                        readonly property bool entryIsSet: entry ? entry.isSet : false

                        readonly property bool isFirst: index === 0
                        readonly property bool isSelected: index === Services.Wallpaper.selectedIndex
                        readonly property bool isCurrent: Services.Wallpaper.currentWallpaper === entryName

                        x: index * (root.cellWidth - root.slant)
                        width: root.cellWidth
                        height: root.bandHeight
                        z: index

                        // Parallelogram mask — only cuts the left edge.
                        Item {
                            id: cellMask
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true

                            Shape {
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    fillColor: "white"
                                    strokeWidth: -1
                                    startX: cell.isFirst ? 0 : root.slant
                                    startY: 0
                                    PathLine { x: root.cellWidth; y: 0 }
                                    PathLine { x: root.cellWidth; y: root.bandHeight }
                                    PathLine { x: 0; y: root.bandHeight }
                                }
                            }
                        }

                        // Masked content — image + overlays clipped to parallelogram
                        Item {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: cellMask
                            }

                            Image {
                                anchors.fill: parent
                                source: cell.entry ? "file://" + Services.Wallpaper.previewPath(cell.entry) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(480, 270)
                            }

                            // Hover/selection overlay
                            Rectangle {
                                anchors.fill: parent
                                color: Utils.Theme.hoverBg
                                opacity: cellMouse.containsMouse || cell.isSelected ? 0.4 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                                }
                            }

                            // Current wallpaper accent bar
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 3
                                color: Utils.Theme.accent
                                visible: cell.isCurrent
                            }

                            // Set indicator badge
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Utils.Theme.spacingSmall
                                width: setLabel.implicitWidth + Utils.Theme.spacingSmall * 2
                                height: setLabel.implicitHeight + 4
                                radius: height / 2
                                color: Utils.Theme.crust
                                opacity: 0.85
                                visible: cell.entryIsSet && root.filter !== "sets"

                                Text {
                                    id: setLabel
                                    anchors.centerIn: parent
                                    text: "Set"
                                    font.family: Utils.Theme.fontFamily
                                    font.pixelSize: Utils.Theme.fontSizeXSmall
                                    color: Utils.Theme.accent
                                    font.bold: true
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
                                visible: (cellMouse.containsMouse || cell.isSelected) && !cell.isCurrent

                                Text {
                                    id: nameLabel
                                    anchors.centerIn: parent
                                    text: cell.entryIsSet ? cell.entryName : cell.entryName.replace(/\.[^.]+$/, "")
                                    font.family: Utils.Theme.fontFamily
                                    font.pixelSize: Utils.Theme.fontSizeXSmall
                                    color: Utils.Theme.text
                                    elide: Text.ElideMiddle
                                    width: parent.width - Utils.Theme.spacingSmall * 2
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Diagonal divider line between cells
                        Shape {
                            anchors.fill: parent
                            visible: !cell.isFirst
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: Utils.Theme.crust
                                strokeWidth: 2
                                startX: root.slant
                                startY: 0
                                PathLine { x: 0; y: root.bandHeight }
                            }
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (cell.entry)
                                    Services.Wallpaper.applyEntry(cell.entry);
                            }
                            onContainsMouseChanged: {
                                if (containsMouse)
                                    Services.Wallpaper.selectedIndex = cell.index;
                            }
                        }
                    }
                }
            }
        }

        // Horizontal scroll indicator
        ScrollBar {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            orientation: Qt.Horizontal
            size: bandFlick.width / Math.max(1, bandFlick.contentWidth)
            position: bandFlick.contentX / Math.max(1, bandFlick.contentWidth)
            visible: bandFlick.contentWidth > bandFlick.width
            contentItem: Rectangle {
                radius: 2
                color: Utils.Theme.overlay0
                opacity: 0.6
            }
        }
    }

    // ── Empty state ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.bandHeight
        visible: root.filteredEntries.length === 0

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
                text: root.filter === "all" ? "No wallpapers for this theme"
                    : root.filter === "singles" ? "No single wallpapers"
                    : "No wallpaper sets"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.disabledText
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Edit ~/.config/wallpapers/wallpapers.json"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeXSmall
                color: Utils.Theme.subtleText
            }
        }
    }

    // Reset scroll when entering wallpaper mode
    Connections {
        target: Services.Launcher
        function on_SubmenuChanged(): void {
            if (Services.Launcher._submenu === "wallpaper") {
                root.forceActiveFocus();
                root.filter = "all";
                Services.Wallpaper.selectedIndex = 0;
                bandScrollBehavior.enabled = false;
                bandFlick.contentX = 0;
                bandScrollBehavior.enabled = true;
            }
        }
    }
}
