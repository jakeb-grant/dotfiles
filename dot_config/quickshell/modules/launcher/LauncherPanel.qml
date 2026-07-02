pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services as Services
import qs.utils as Utils
import qs.modules.wallpaper

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal
    clip: true

    readonly property bool wallpaperMode: Services.Launcher.submenu === "wallpaper"

    // #6: Open/close animation (opacity + scale from bottom)
    property bool _opening: false
    opacity: 0
    scale: 0.88
    transformOrigin: Item.Bottom

    Behavior on opacity {
        NumberAnimation {
            duration: root._opening ? 300 : 200
            easing.type: root._opening ? Easing.OutCubic : Easing.InCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root._opening ? 350 : 200
            easing.type: root._opening ? Easing.OutBack : Easing.InCubic
        }
    }

    // ── Wallpaper picker (embedded in launcher) ──
    WallpaperPicker {
        id: wallpaperPicker
        Layout.fillWidth: true
        visible: root.wallpaperMode
        focus: root.wallpaperMode
        opacity: root.wallpaperMode ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Utils.Theme.animDurationSmall
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Utils.Theme.animCurveStandard
            }
        }
    }

    // ── Results list ──
    Flickable {
        id: resultsFlick

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(resultsColumn.implicitHeight,
            Utils.Theme.launcherMaxHeight)
        visible: Services.Launcher.results.length > 0 && !root.wallpaperMode
        clip: true
        contentHeight: resultsColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        // #11: Smooth scroll on keyboard nav (disabled during snap resets)
        Behavior on contentY {
            id: scrollBehavior
            enabled: true
            NumberAnimation {
                duration: Utils.Theme.animDurationFast
                easing.type: Easing.OutCubic
            }
        }

        // #8: Scrollbar
        ScrollBar.vertical: ScrollBar {
            policy: resultsFlick.contentHeight > resultsFlick.height
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

        // Auto-scroll to keep selected item visible
        function ensureVisible(idx: int): void {
            const itemY = idx * (Utils.Theme.launcherItemHeight + Utils.Theme.spacingTiny);
            const itemBottom = itemY + Utils.Theme.launcherItemHeight;
            if (itemY < contentY)
                contentY = itemY;
            else if (itemBottom > contentY + height)
                contentY = itemBottom - height;
        }

        ColumnLayout {
            id: resultsColumn
            width: resultsFlick.width
            spacing: Utils.Theme.spacingTiny

            Repeater {
                model: Services.Launcher.results

                delegate: Rectangle {
                    id: item

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.leftMargin: Utils.Theme.spacingTiny
                    Layout.rightMargin: Utils.Theme.spacingTiny
                    height: Utils.Theme.launcherItemHeight
                    radius: Utils.Theme.listItemRadius
                    color: index === Services.Launcher.selectedIndex
                        ? Utils.Theme.surface1
                        : itemMouse.containsMouse
                            ? Utils.Theme.hoverBg : "transparent"

                    // Staggered entrance
                    property bool _entered: false
                    opacity: _entered ? 1 : 0
                    Timer {
                        running: true
                        interval: 10 + (item.index * 25)
                        onTriggered: item._entered = true
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    transform: Translate {
                        x: item._entered ? 0 : 8
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                    }

                    // #9: Add easing to hover color animation
                    Behavior on color {
                        ColorAnimation {
                            duration: Utils.Theme.animDurationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Utils.Theme.spacingNormal
                        anchors.rightMargin: Utils.Theme.spacingNormal
                        spacing: Utils.Theme.spacingNormal

                        // Icon from desktop entry or named icon
                        Image {
                            id: appIcon
                            source: (item.modelData.icon ?? "").length > 0
                                ? Quickshell.iconPath(item.modelData.icon, true) : ""
                            sourceSize.width: Utils.Theme.iconSize
                            sourceSize.height: Utils.Theme.iconSize
                            Layout.preferredWidth: Utils.Theme.iconSize
                            Layout.preferredHeight: Utils.Theme.iconSize
                            visible: status === Image.Ready
                        }

                        // Fallback: materialIcon or category guess
                        Utils.MaterialIcon {
                            text: (item.modelData.materialIcon ?? "").length > 0
                                ? item.modelData.materialIcon
                                : Utils.Icons.getAppCategoryIcon(
                                    item.modelData.name ?? "", "apps")
                            font.pixelSize: Utils.Theme.iconSize
                            color: Utils.Theme.subtext0
                            visible: !appIcon.visible
                            Layout.preferredWidth: Utils.Theme.iconSize
                            Layout.preferredHeight: Utils.Theme.iconSize
                        }

                        // Name
                        Text {
                            text: item.modelData.name ?? ""
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.fontSize
                            color: Utils.Theme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // "Active" label for themes (fixed width so swatches align)
                        Text {
                            text: (item.modelData.subtitle ?? "").length > 0
                                ? item.modelData.subtitle : ""
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.fontSizeSmall
                            color: Utils.Theme.accent
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                            visible: (item.modelData.swatches ?? []).length > 0
                        }

                        // Color swatches (theme entries)
                        Row {
                            spacing: 3
                            visible: (item.modelData.swatches ?? []).length > 0
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: item.modelData.swatches ?? []

                                Rectangle {
                                    required property string modelData
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: modelData
                                }
                            }
                        }

                        // Subtitle (comment, shortcut, calc result, etc.)
                        Text {
                            text: item.modelData.subtitle ?? ""
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: item.modelData.type === "calc"
                                ? Utils.Theme.fontSize : Utils.Theme.fontSizeSmall
                            color: item.modelData.type === "calc"
                                ? Utils.Theme.accent : Utils.Theme.subtext0
                            elide: Text.ElideRight
                            Layout.maximumWidth: root.width * 0.35
                            visible: text.length > 0 && (item.modelData.swatches ?? []).length === 0
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Launcher.launch(item.modelData)
                    }
                }
            }
        }
    }

    // #3: "No results" placeholder
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Utils.Theme.launcherItemHeight
        visible: Services.Launcher.query.length > 0
            && Services.Launcher.results.length === 0
            && !root.wallpaperMode

        Text {
            anchors.centerIn: parent
            text: "No results"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.disabledText
        }
    }

    // ── Search bar ──
    Rectangle {
        id: searchBar

        Layout.fillWidth: true
        height: Utils.Theme.launcherInputHeight
        radius: Utils.Theme.roundingSmall
        color: Utils.Theme.surface0
        visible: !root.wallpaperMode

        // #7: Focus indicator
        border.width: 1.5
        border.color: searchInput.activeFocus ? Utils.Theme.accent : "transparent"

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Utils.Theme.spacingNormal
            anchors.rightMargin: Utils.Theme.spacingNormal
            spacing: Utils.Theme.spacingNormal

            Utils.MaterialIcon {
                text: Services.Launcher.mode === "calc" ? "calculate" : "search"
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtext0
            }

            TextInput {
                id: searchInput

                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSize
                color: Utils.Theme.text
                clip: true

                // Sync: input → service
                onTextChanged: {
                    if (Services.Launcher.query !== text)
                        Services.Launcher.query = text;
                }
                // Sync: service → input (e.g. reset on reopen)
                Connections {
                    target: Services.Launcher
                    function onQueryChanged(): void {
                        if (searchInput.text !== Services.Launcher.query)
                            searchInput.text = Services.Launcher.query;
                    }
                }

                // Placeholder
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "Search…"
                    font: searchInput.font
                    color: Utils.Theme.overlay0
                    visible: searchInput.text.length === 0
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        if (!Services.Launcher.goBack())
                            Services.Launcher.visible = false;
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter: {
                        Services.Launcher.flush();
                        const len = Services.Launcher.results.length;
                        if (len > 0) {
                            const idx = Math.min(Services.Launcher.selectedIndex, len - 1);
                            Services.Launcher.launch(Services.Launcher.results[idx]);
                        }
                        event.accepted = true;
                        break;
                    }
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        Services.Launcher.selectedIndex = Math.min(
                            Services.Launcher.selectedIndex + 1,
                            Services.Launcher.results.length - 1);
                        resultsFlick.ensureVisible(Services.Launcher.selectedIndex);
                        event.accepted = true;
                        break;
                    case Qt.Key_Up:
                    case Qt.Key_Backtab: // #2: Shift+Tab
                        Services.Launcher.selectedIndex = Math.max(
                            Services.Launcher.selectedIndex - 1, 0);
                        resultsFlick.ensureVisible(Services.Launcher.selectedIndex);
                        event.accepted = true;
                        break;
                    }
                }
            }
        }
    }

    // #1: Reset scroll position when results change
    Connections {
        target: Services.Launcher
        function onResultsChanged(): void {
            scrollBehavior.enabled = false;
            resultsFlick.contentY = 0;
            scrollBehavior.enabled = true;
        }
        function onVisibleChanged(): void {
            if (Services.Launcher.visible) {
                searchInput.forceActiveFocus();
                // #6: Trigger entrance animation
                root._opening = true;
                root.opacity = 1;
                root.scale = 1;
            } else {
                root._opening = false;
                root.opacity = 0;
                root.scale = 0.88;
            }
        }
        function onSubmenuChanged(): void {
            if (Services.Launcher.submenu !== "wallpaper")
                searchInput.forceActiveFocus();
        }
    }
}
