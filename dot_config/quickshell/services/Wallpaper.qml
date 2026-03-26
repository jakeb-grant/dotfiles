pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.utils as Utils

Singleton {
    id: root

    // ── Public API ──
    property var entries: []
    property string currentWallpaper: ""
    property int selectedIndex: 0
    property string paletteSlug: ""
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.config/wallpapers"

    // Full path to a displayable image (for lock screen, etc.)
    // For singles: wallpaperDir + "/" + filename
    // For sets: wallpaperDir + "/" + first image
    readonly property string lockScreenImage: {
        if (!currentWallpaper) return "";
        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            if (e.name === currentWallpaper && e.isSet)
                return e.images.length > 0 ? wallpaperDir + "/" + e.images[0] : "";
        }
        return wallpaperDir + "/" + currentWallpaper;
    }

    // ── JSON Config ──
    FileView {
        id: configFile
        path: root.wallpaperDir + "/wallpapers.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: {
            reload();
            root._rev++;
        }
    }

    property int _rev: 0
    readonly property var _config: {
        void root._rev;
        try { return JSON.parse(configFile.text()); }
        catch(e) { return {}; }
    }

    // ── Theme tracking ──
    function _deriveSlug(): string {
        return Utils.Theme.themeName
            .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            .toLowerCase().replace(/ /g, "-");
    }

    Connections {
        target: Utils.Theme
        function onThemeNameChanged(): void {
            const newSlug = root._deriveSlug();
            if (newSlug === root.paletteSlug) return;
            root.paletteSlug = newSlug;
            root._autoSetOnRefresh = true;
        }
    }

    Component.onCompleted: {
        paletteSlug = _deriveSlug();
        _autoSetOnRefresh = true;
    }

    property bool _autoSetOnRefresh: false

    // ── Rebuild entries when config or theme changes ──
    onPaletteSlugChanged: _rebuildEntries()
    on_ConfigChanged: _rebuildEntries()

    function _matchesPalette(palettes): bool {
        if (!Array.isArray(palettes)) return false;
        for (let i = 0; i < palettes.length; i++) {
            const p = palettes[i];
            if (p === "*" || p === paletteSlug) return true;
            if (p.includes("*")) {
                const regex = new RegExp("^" + p.replace(/\*/g, ".*") + "$");
                if (regex.test(paletteSlug)) return true;
            }
        }
        return false;
    }

    function _rebuildEntries(): void {
        const cfg = _config;
        const result = [];

        const walls = cfg.wallpapers ?? [];
        for (let i = 0; i < walls.length; i++) {
            if (_matchesPalette(walls[i].palettes))
                result.push({ name: walls[i].file, isSet: false });
        }

        const sets = cfg.sets ?? [];
        for (let i = 0; i < sets.length; i++) {
            if (_matchesPalette(sets[i].palettes))
                result.push({
                    name: sets[i].name,
                    isSet: true,
                    images: sets[i].images ?? []
                });
        }

        entries = result;
        selectedIndex = 0;

        if (_autoSetOnRefresh && entries.length > 0) {
            const idx = Math.floor(Math.random() * entries.length);
            applyEntry(entries[idx]);
        }
        _autoSetOnRefresh = false;
    }

    // ── Public functions ──
    function refreshForLauncher(): void {
        selectedIndex = 0;
    }

    function previewPath(entry): string {
        if (entry.isSet)
            return entry.images.length > 0 ? wallpaperDir + "/" + entry.images[0] : "";
        return wallpaperDir + "/" + entry.name;
    }

    function applyEntry(entry): void {
        if (entry.isSet)
            _applySet(entry);
        else
            setWallpaper(entry.name);
    }

    function setWallpaper(filename: string): void {
        const path = wallpaperDir + "/" + filename;
        _applyProc.running = false;
        _applyProc.command = ["sh", "-c",
            `awww img "${path}" --transition-type center --transition-duration 1 --transition-fps 60`];
        _applyProc.running = true;
        currentWallpaper = filename;
    }

    function _applySet(entry): void {
        const images = entry.images ?? [];
        if (images.length === 0) return;

        const screens = Quickshell.screens;
        const monitors = [];
        for (let i = 0; i < screens.length; i++) {
            const mon = Hyprland.monitorFor(screens[i]);
            if (mon) monitors.push({ name: mon.name, x: mon.x, y: mon.y });
        }
        monitors.sort((a, b) => a.x - b.x || a.y - b.y);
        if (monitors.length === 0) return;

        let script = "#!/bin/sh\n";
        for (let i = 0; i < monitors.length; i++) {
            const img = images[i % images.length];
            const path = wallpaperDir + "/" + img;
            script += `awww img "${path}" --outputs "${monitors[i].name}" --transition-type center --transition-duration 1 --transition-fps 60 &\n`;
        }
        script += "wait\n";

        _applyProc.running = false;
        _applyProc.command = ["sh", "-c", script];
        _applyProc.running = true;
        currentWallpaper = entry.name;
    }

    Process { id: _applyProc }
}
