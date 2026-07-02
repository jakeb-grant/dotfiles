pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingSmall

    readonly property var singleEntries: {
        const all = Services.Wallpaper.entries;
        const result = [];
        for (let i = 0; i < all.length; i++)
            if (!all[i].isSet) result.push(all[i]);
        return result;
    }

    readonly property var setEntries: {
        const all = Services.Wallpaper.entries;
        const result = [];
        for (let i = 0; i < all.length; i++)
            if (all[i].isSet) result.push(all[i]);
        return result;
    }

    // Which band has keyboard focus: 0 = singles, 1 = sets
    property int activeRow: singleEntries.length > 0 ? 0 : 1

    readonly property var _activeBand: activeRow === 0 ? singlesBand : setsBand
    readonly property var _activeEntries: activeRow === 0 ? singleEntries : setEntries

    function _switchRow(dir: int): void {
        if (dir < 0 && activeRow === 1 && singleEntries.length > 0)
            activeRow = 0;
        else if (dir > 0 && activeRow === 0 && setEntries.length > 0)
            activeRow = 1;
    }

    Keys.onPressed: event => {
        const entries = root._activeEntries;
        const band = root._activeBand;
        const count = entries.length;

        switch (event.key) {
        case Qt.Key_Escape:
            if (!Services.Launcher.goBack())
                Services.Launcher.visible = false;
            event.accepted = true;
            break;
        case Qt.Key_Up:
            root._switchRow(-1);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            root._switchRow(1);
            event.accepted = true;
            break;
        case Qt.Key_Left:
            if (count > 0) {
                band.selectedIndex = Math.max(band.selectedIndex - 1, 0);
                band.ensureVisible(band.selectedIndex);
            }
            event.accepted = true;
            break;
        case Qt.Key_Right:
        case Qt.Key_Tab:
            if (count > 0) {
                band.selectedIndex = Math.min(band.selectedIndex + 1, count - 1);
                band.ensureVisible(band.selectedIndex);
            }
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (count > 0) {
                const idx = Math.min(band.selectedIndex, count - 1);
                if (idx >= 0)
                    Services.Wallpaper.applyEntry(entries[idx]);
            }
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

        Text {
            text: Utils.Theme.themeName
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeXSmall
            color: Utils.Theme.subtext0
        }
    }

    // ── Singles section ──
    Text {
        text: "Wallpapers"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeXSmall
        font.bold: true
        color: Utils.Theme.subtext0
        visible: singlesBand.visible
    }

    WallpaperBand {
        id: singlesBand
        Layout.fillWidth: true
        entries: root.singleEntries
        isActiveBand: root.activeRow === 0
        onActivateRequested: root.activeRow = 0
    }

    // ── Sets section ──
    Text {
        text: "Sets"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeXSmall
        font.bold: true
        color: Utils.Theme.subtext0
        visible: setsBand.visible
    }

    WallpaperBand {
        id: setsBand
        Layout.fillWidth: true
        entries: root.setEntries
        isActiveBand: root.activeRow === 1
        onActivateRequested: root.activeRow = 1
    }

    // ── Empty state ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        visible: root.singleEntries.length === 0 && root.setEntries.length === 0

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
        function onSubmenuChanged(): void {
            if (Services.Launcher.submenu === "wallpaper") {
                root.forceActiveFocus();
                root.activeRow = root.singleEntries.length > 0 ? 0 : 1;
                singlesBand.selectedIndex = 0;
                setsBand.selectedIndex = 0;
            }
        }
    }
}
