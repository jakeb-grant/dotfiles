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
    readonly property string _stateFile: wallpaperDir + "/.current"

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

    // ── Persistence ──
    FileView {
        id: stateFile
        path: root._stateFile
        blockLoading: true
    }

    onCurrentWallpaperChanged: {
        if (currentWallpaper) {
            _saveProc.command = ["sh", "-c", `printf '%s' "${currentWallpaper}" > "${_stateFile}"`];
            _saveProc.running = true;
        }
    }

    Process { id: _saveProc }

    Component.onCompleted: {
        const saved = stateFile.text().trim();
        if (saved) _savedWallpaper = saved;
        _autoSetOnRefresh = true;
        paletteSlug = _deriveSlug(); // must be last — triggers _rebuildEntries()
    }

    property string _savedWallpaper: ""
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

        // Only consume the auto-set flag when entries are actually available;
        // first _rebuildEntries() during startup may run with empty entries
        // (config file not yet loaded) and we want the restore to fire when
        // entries arrive.
        if (_autoSetOnRefresh && entries.length > 0) {
            _autoSetOnRefresh = false;
            let restored = false;
            const saved = _savedWallpaper;
            _savedWallpaper = "";  // one-shot — consume regardless of match
            if (saved) {
                for (let i = 0; i < entries.length; i++) {
                    if (entries[i].name === saved) {
                        applyEntry(entries[i]);
                        restored = true;
                        break;
                    }
                }
            }
            if (!restored)
                applyEntry(_defaultEntry());
        }
    }

    // Deterministic pick for a freshly matched theme: the config's `defaults`
    // map names a wallpaper/set per palette slug (exact slug wins, then
    // wildcard keys like "rose-pine*", then "*"), falling back to the first
    // matching entry when nothing is configured or the named entry doesn't
    // apply to this theme.
    function _defaultEntry(): var {
        const defaults = _config.defaults ?? {};
        let name = defaults[paletteSlug];
        if (name === undefined) {
            for (const key in defaults) {
                if (key !== "*" && key.includes("*")) {
                    const regex = new RegExp("^" + key.replace(/\*/g, ".*") + "$");
                    if (regex.test(paletteSlug)) {
                        name = defaults[key];
                        break;
                    }
                }
            }
        }
        if (name === undefined)
            name = defaults["*"];
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].name === name)
                return entries[i];
        }
        return entries[0];
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

    // Re-apply set wallpaper when monitors appear/change (startup race).
    // Debounced to avoid rapid-fire re-applies as monitors come online.
    Timer {
        id: screenDebounce
        interval: 200
        onTriggered: {
            if (!root.currentWallpaper) return;
            for (let i = 0; i < root.entries.length; i++) {
                const e = root.entries[i];
                if (e.name === root.currentWallpaper && e.isSet) {
                    root._applySet(e);
                    return;
                }
            }
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            screenDebounce.restart();
        }
    }
}
