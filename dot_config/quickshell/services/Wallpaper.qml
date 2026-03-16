pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils as Utils

Singleton {
    id: root

    property bool visible: false
    property var wallpapers: []
    property string currentWallpaper: ""
    property int selectedIndex: 0
    property var activeScreen: null

    property string paletteSlug: ""
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.config/wallpapers/" + paletteSlug

    property var _buffer: []
    property string _listingSlug: ""

    function _deriveSlug(): string {
        return Utils.Theme.themeName
            .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            .toLowerCase().replace(/ /g, "-");
    }

    // React to theme changes via explicit Connections — more reliable
    // than cross-singleton binding on derived var properties
    Connections {
        target: Utils.Theme
        function onThemeNameChanged(): void {
            const newSlug = root._deriveSlug();
            if (newSlug === root.paletteSlug) return;
            root.paletteSlug = newSlug;
            root.wallpapers = [];
            root.selectedIndex = 0;
            if (root.visible)
                root._refreshList();
        }
    }

    Component.onCompleted: {
        paletteSlug = _deriveSlug();
    }

    Process {
        id: _listProc
        onRunningChanged: {
            if (running) {
                root._buffer = [];
                root._listingSlug = root.paletteSlug;
            } else {
                if (root._listingSlug === root.paletteSlug) {
                    root._buffer.sort();
                    root.wallpapers = root._buffer;
                }
                root._buffer = [];
            }
        }
        stdout: SplitParser {
            onRead: data => {
                const name = data.trim();
                if (name.length > 0 && /\.(jpe?g|png|webp)$/i.test(name))
                    root._buffer.push(name);
            }
        }
    }

    Process {
        id: _setProc
    }

    function _refreshList(): void {
        _listProc.running = false;
        _listProc.command = ["ls", "-1", wallpaperDir];
        _listProc.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            _refreshList();
        }
    }

    function toggle(): void {
        visible = !visible;
    }

    function setWallpaper(filename: string): void {
        const path = wallpaperDir + "/" + filename;
        _setProc.running = false;
        _setProc.command = ["awww", "img", path,
            "--transition-type", "center",
            "--transition-duration", "1",
            "--transition-fps", "60"];
        _setProc.running = true;
        currentWallpaper = filename;
    }
}
