pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.services as Services
import qs.utils as Utils

Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0
    property var results: []
    // ShellScreen the launcher opened on (null when closed) — same
    // convention as Popout.activeScreen
    property var activeScreen: null

    readonly property string mode: query.startsWith("=") ? "calc" : "unified"
    readonly property string effectiveQuery: mode === "calc" ? query.substring(1).trim() : query

    property string submenu: ""
    property var _clipboardEntries: []
    property var _themes: []
    property var _themeBuffer: []

    // Static keybind/action/main-menu tables live in LauncherProviders.qml.

    // ── Process children ──

    Process { id: _clipDecodeProc }
    Process { id: _copyProc }

    property var _clipBuffer: []

    Process {
        id: _clipListProc
        command: ["cliphist", "list"]
        onRunningChanged: {
            if (running) {
                root._clipBuffer = [];
            } else {
                root._clipboardEntries = root._clipBuffer;
                root._clipBuffer = [];
            }
        }
        stdout: SplitParser {
            onRead: data => {
                if (root._clipBuffer.length >= 100) return;
                const idx = data.indexOf("\t");
                if (idx < 0) return;
                const id = data.substring(0, idx);
                const text = data.substring(idx + 1).trim();
                if (text.length === 0) return;
                root._clipBuffer.push({ id: id, text: text });
            }
        }
    }

    Process {
        id: _themeScanProc
        onRunningChanged: {
            if (running) {
                root._themeBuffer = [];
            } else {
                root._themes = root._themeBuffer;
                root._themeBuffer = [];
                if (root.submenu === "themes")
                    root.results = root._themesToResults();
            }
        }
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                if (parts.length >= 2)
                    root._themeBuffer.push({
                        file: parts[0],
                        name: parts[1],
                        swatches: parts.slice(2),
                    });
            }
        }
    }

    function _scanThemes(): void {
        _themeScanProc.running = false;
        _themeScanProc.command = ["theme-switch", "--list"];
        _themeScanProc.running = true;
    }

    Process {
        id: _themeSwitchProc
    }

    function _switchTheme(file: string): void {
        _themeSwitchProc.running = false;
        _themeSwitchProc.command = ["theme-switch", file.replace(".json", "")];
        _themeSwitchProc.running = true;
    }

    Connections {
        target: Utils.Theme
        function onThemeNameChanged(): void {
            if (root.submenu === "themes")
                root.results = root._themesToResults();
        }
    }

    onVisibleChanged: {
        if (visible) {
            query = "";
            selectedIndex = 0;
            submenu = "";
            results = Services.LauncherProviders.mainItems;
            _clipboardEntries = [];
            _clipListProc.running = true;
            // Resolve to the Quickshell.screens instance — Drawers compares by
            // object identity, and HyprlandMonitor.screen is a distinct wrapper
            // for the same screen. focusedMonitor can also be null before any
            // focus event, so fall back to the first screen.
            const focusedName = Hyprland.focusedMonitor?.name ?? "";
            const screens = Quickshell.screens;
            let scr = null;
            for (let i = 0; i < screens.length; i++) {
                if (screens[i].name === focusedName) {
                    scr = screens[i];
                    break;
                }
            }
            activeScreen = scr ?? screens[0] ?? null;
        } else {
            activeScreen = null;
        }
    }

    onQueryChanged: _debounce.restart()

    Timer {
        id: _debounce
        interval: 50
        onTriggered: root._filter()
    }

    // Force a pending debounced filter to run now. Without this, hitting Enter
    // within the debounce window launches stale/empty results — the "didn't
    // launch on the first try" symptom for fast typists.
    function flush(): void {
        if (_debounce.running) {
            _debounce.stop();
            _filter();
        }
    }

    function toggle(): void {
        visible = !visible;
    }

    function goBack(): bool {
        if (submenu !== "") {
            submenu = "";
            query = "";
            results = Services.LauncherProviders.mainItems;
            selectedIndex = 0;
            return true;
        }
        return false;
    }

    // Launch through Hyprland's own exec so the new window inherits the
    // workspace active at launch time (Hyprland tracks the spawned PID).
    // Spawning detached (execDetached / DesktopEntry.execute) skips this,
    // leaving the window to land on whatever workspace is focused at map time.
    // Dispatch strings are evaluated as Lua by this Hyprland, so call the
    // hl.dsp.exec_cmd API. Each argv item is shell-quoted, then the whole
    // command line is escaped for the Lua double-quoted string literal.
    function _execTracked(argv): void {
        const cmd = argv.map(a => "'" + String(a).replace(/'/g, "'\\''") + "'").join(" ");
        const lua = cmd.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
        Hyprland.dispatch('hl.dsp.exec_cmd("' + lua + '")');
    }

    function launch(result): void {
        switch (result.type) {
        case "submenu":
            _debounce.stop();
            submenu = result._data;
            query = "";
            if (result._data === "keybinds") {
                results = Services.LauncherProviders.keybindItems;
                selectedIndex = 0;
            } else if (result._data === "clipboard") {
                results = _clipboardToResults(_clipboardEntries);
                selectedIndex = 0;
            } else if (result._data === "notifhistory") {
                results = _notifHistoryToResults(Services.Notifications.history);
                selectedIndex = 0;
            } else if (result._data === "themes") {
                _scanThemes();
                results = _themesToResults();
                selectedIndex = 0;
            }
            return;
        case "app":
            if (result._data.runInTerminal) {
                _execTracked(["ghostty", "-e", ...result._data.command]);
            } else {
                _execTracked(result._data.command);
            }
            break;
        case "window":
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + result._data + '" })');
            break;
        case "calc":
            _copyProc.running = false;
            // "--" everywhere text reaches wl-copy: a leading "-" (negative
            // calc result, "-50% sale" summary) parses as flags otherwise —
            // and "-c" *clears* the clipboard.
            _copyProc.command = ["wl-copy", "--", result.subtitle];
            _copyProc.running = true;
            break;
        case "clipboard":
            _clipDecodeProc.running = false;
            _clipDecodeProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", result._data];
            _clipDecodeProc.running = true;
            break;
        // History entries copy their text — same Enter semantics as the
        // clipboard submenu, and handy for codes/URLs in old notifications.
        case "notifhistory":
            _copyProc.running = false;
            _copyProc.command = ["wl-copy", "--", (result._data.summary + "\n" + result._data.body).trim()];
            _copyProc.running = true;
            break;
        case "placeholder":
            return;
        case "theme":
            _switchTheme(result._data);
            return;
        case "wallpaper":
            _debounce.stop();
            submenu = "wallpaper";
            query = "";
            Services.Wallpaper.refreshForLauncher();
            return;
        case "keybind":
        case "action":
            // Close first so interactive tools (slurp, etc.) can grab the screen
            visible = false;
            if (result._special === "dnd") {
                Services.Notifications.toggleDnd();
            } else if (result._isDispatch) {
                Hyprland.dispatch(result._data);
            } else {
                Quickshell.execDetached(["sh", "-c", result._data]);
            }
            return;
        }
        visible = false;
    }

    // ── Provider functions ──

    // Shared scoring pass: `primary` earns the startsWith/includes ladder
    // (w[0]/w[1]), `secondary` only the catch-all tier (w[2]). Any term that
    // misses both fields disqualifies the candidate. Both fields must already
    // be lowercased; terms never contain whitespace (query is split on it),
    // so secondary can safely be several fields joined with spaces.
    function _score(terms, primary, secondary, w): real {
        let score = 0;
        for (const term of terms) {
            if (primary.startsWith(term)) score += w[0];
            else if (primary.includes(term)) score += w[1];
            else if (secondary.includes(term)) score += w[2];
            else return 0;
        }
        return score;
    }

    function _filterApps(terms): var {
        const out = [];
        for (const app of DesktopEntries.applications.values) {
            const name = (app.name ?? "").toLowerCase();
            const rest = ((app.comment ?? "") + " " + (app.categories ?? []).join(" ")).toLowerCase();
            const score = _score(terms, name, rest, [3, 2, 1]);
            if (score > 0) {
                out.push({
                    type: "app",
                    name: app.name ?? "",
                    subtitle: app.comment ?? "",
                    icon: app.icon ?? "",
                    materialIcon: "",
                    score: score - name.length / 100,
                    _data: app,
                });
            }
        }
        return out;
    }

    function _filterWindows(terms): var {
        const out = [];
        for (const t of Hyprland.toplevels?.values ?? []) {
            const title = (t.lastIpcObject?.title ?? "").toLowerCase();
            const cls = (t.lastIpcObject?.class ?? "").toLowerCase();
            const score = _score(terms, title, cls, [3, 2, 1]);
            if (score > 0) {
                out.push({
                    type: "window",
                    name: t.lastIpcObject?.title ?? "",
                    subtitle: t.lastIpcObject?.class ?? "",
                    icon: "",
                    materialIcon: "desktop_windows",
                    score: score,
                    _data: t.lastIpcObject?.address ?? "",
                });
            }
        }
        return out;
    }

    function _filterKeybinds(terms): var {
        const out = [];
        for (const kb of Services.LauncherProviders.keybinds) {
            const rest = (kb.shortcut + " " + kb.keywords.join(" ")).toLowerCase();
            const score = _score(terms, kb.name.toLowerCase(), rest, [2.5, 1.5, 0.5]);
            if (score > 0) {
                out.push({
                    type: "keybind",
                    name: kb.name,
                    subtitle: kb.shortcut,
                    icon: "",
                    materialIcon: "keyboard",
                    score: score,
                    _data: kb.dispatch ?? kb.command,
                    _isDispatch: !!kb.dispatch,
                });
            }
        }
        return out;
    }

    function _filterActions(terms): var {
        const out = [];
        for (const act of Services.LauncherProviders.actions) {
            const score = _score(terms, act.name.toLowerCase(),
                                 act.keywords.join(" "), [2.5, 1.5, 0.5]);
            if (score > 0) {
                out.push({
                    type: "action",
                    name: act.name,
                    subtitle: act.subtitle ?? "",
                    icon: act.icon,
                    materialIcon: act.materialIcon ?? "",
                    score: score,
                    _data: act.command ?? "",
                    _special: act.special ?? "",
                });
            }
        }
        return out;
    }

    function _formatClipEntry(entry): var {
        const binaryMatch = entry.text.match(/^\[\[ binary data (\d+\s*\w+) (\w+) (\d+x\d+) \]\]$/);
        if (binaryMatch) {
            return {
                name: "Image — " + binaryMatch[1] + " " + binaryMatch[2] + " " + binaryMatch[3],
                materialIcon: "image",
            };
        }
        return {
            name: entry.text.length > 80 ? entry.text.substring(0, 80) + "…" : entry.text,
            materialIcon: "content_paste",
        };
    }

    function _clipboardToResults(entries): var {
        const out = [];
        for (const entry of entries) {
            const fmt = _formatClipEntry(entry);
            out.push({
                type: "clipboard",
                name: fmt.name,
                subtitle: "",
                icon: "",
                materialIcon: fmt.materialIcon,
                score: 0,
                _data: entry.id,
            });
        }
        return out;
    }

    function _relTime(ms): string {
        const m = Math.floor(ms / 60000);
        if (m < 1) return "now";
        if (m < 60) return m + "m ago";
        const h = Math.floor(m / 60);
        if (h < 24) return h + "h ago";
        return Math.floor(h / 24) + "d ago";
    }

    // Notification history (submenu-only — not in the unified search: stale
    // notification text scoring against apps/windows is noise, and the
    // clipboard provider already covers "text I saw recently").
    function _notifHistoryToResults(entries): var {
        if (entries.length === 0) {
            return [{
                type: "placeholder",
                name: "No notifications yet",
                subtitle: "",
                icon: "",
                materialIcon: "notifications_none",
                score: 0,
                _data: "",
            }];
        }
        const now = Date.now();
        const out = [];
        for (const e of entries) {
            out.push({
                type: "notifhistory",
                name: e.summary || e.body || e.appName || "(empty)",
                subtitle: (e.appName ? e.appName + " · " : "") + _relTime(now - e.time),
                icon: e.appIcon ?? "",
                materialIcon: e.critical ? "priority_high" : "notifications",
                score: 0,
                _data: e,
            });
        }
        return out;
    }

    function _filterNotifHistory(terms): var {
        const hits = Services.Notifications.history.filter(e => {
            const text = (e.summary + " " + e.body + " " + e.appName).toLowerCase();
            return terms.every(t => text.includes(t));
        });
        return hits.length === 0 ? [] : _notifHistoryToResults(hits);
    }

    function _themesToResults(): var {
        const out = [];
        for (const t of _themes) {
            out.push({
                type: "theme",
                name: t.name,
                subtitle: t.name === Utils.Theme.themeName ? "Active" : "",
                icon: "",
                materialIcon: t.name === Utils.Theme.themeName ? "radio_button_checked" : "radio_button_unchecked",
                score: 0,
                _data: t.file,
                swatches: t.swatches ?? [],
            });
        }
        return out;
    }

    // Boolean filter, not the ladder: every term must appear, fixed score 1
    // (clipboard entries rank below any real ladder hit in the unified list).
    function _filterClipboard(terms): var {
        const out = [];
        for (const entry of _clipboardEntries) {
            const text = entry.text.toLowerCase();
            if (terms.every(term => text.includes(term))) {
                const fmt = _formatClipEntry(entry);
                out.push({
                    type: "clipboard",
                    name: fmt.name,
                    subtitle: "",
                    icon: "",
                    materialIcon: fmt.materialIcon,
                    score: 1,
                    _data: entry.id,
                });
            }
        }
        return out;
    }

    function _evalCalc(expr): var {
        if (expr.length === 0) return [];
        const sanitized = expr.replace(/[^0-9.+\-*/()%^ ]/g, "");
        if (sanitized.length === 0) return [];
        const jsExpr = sanitized.replace(/\^/g, "**");
        try {
            const result = eval(jsExpr);
            if (typeof result !== "number" || !isFinite(result)) return [];
            const display = String(result);
            return [{
                type: "calc",
                name: expr,
                subtitle: display,
                icon: "",
                materialIcon: "calculate",
                score: 10,
                _data: display,
            }];
        } catch (e) {
            return [];
        }
    }

    // ── Main filter ──

    function _filter(): void {
        if (effectiveQuery.length === 0) {
            if (submenu === "keybinds") {
                results = Services.LauncherProviders.keybindItems;
            } else if (submenu === "clipboard") {
                results = _clipboardToResults(_clipboardEntries);
            } else if (submenu === "notifhistory") {
                results = _notifHistoryToResults(Services.Notifications.history);
            } else if (submenu === "themes") {
                results = _themesToResults();
            } else {
                results = Services.LauncherProviders.mainItems;
            }
            selectedIndex = 0;
            return;
        }

        if (mode === "calc") {
            results = _evalCalc(effectiveQuery);
            selectedIndex = 0;
            return;
        }

        const terms = effectiveQuery.toLowerCase().split(/\s+/).filter(t => t.length > 0);

        // Filter within submenu if active
        if (submenu === "keybinds") {
            results = _filterKeybinds(terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "clipboard") {
            results = _filterClipboard(terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "notifhistory") {
            results = _filterNotifHistory(terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "themes") {
            results = _themesToResults().filter(t => terms.every(term => t.name.toLowerCase().includes(term)));
            selectedIndex = 0;
            return;
        }

        let all = [
            ..._filterApps(terms),
            ..._filterWindows(terms),
            ..._filterKeybinds(terms),
            ..._filterActions(terms),
            ..._filterClipboard(terms),
        ];
        all.sort((a, b) => b.score - a.score);
        results = all.slice(0, 20);
        selectedIndex = 0;
    }
}
