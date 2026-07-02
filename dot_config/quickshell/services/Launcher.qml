pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
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

    // Tray drill-down state ("traymenu" submenu): the SystemTrayItem whose
    // menu is open, the current DBus menu handle, and parent handles for
    // Escape back-navigation through nested menus.
    property var _trayMenuItem: null
    property var _trayMenuHandle: null
    property var _trayMenuStack: []

    QsMenuOpener {
        id: _trayMenuOpener
        menu: root._trayMenuHandle
    }

    // DBus menu children populate async after the handle is set — rebuild the
    // visible rows as they arrive. A binding, not Connections-on-children: the
    // model object is created and populated within the same signal cascade as
    // the handle change, so a Connections target re-resolves too late and
    // misses the insertions (verified live: rows stayed stale).
    readonly property var _trayMenuChildren: _trayMenuOpener.children?.values ?? []
    on_TrayMenuChildrenChanged: {
        if (submenu === "traymenu") _filter();
    }

    // Wifi scan results land after the submenu opened; same for a bluetooth
    // power flip (its rows swap between device list and the off row).
    Connections {
        target: Services.Network
        function onScanningChanged(): void {
            if (!Services.Network.scanning && root.submenu === "wifi") root._filter();
        }
    }

    Connections {
        target: Services.Bluetooth
        function onPoweredChanged(): void {
            if (root.submenu === "bluetooth") root._filter();
        }
    }

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
            // Release the DBus menu (QsMenuOpener closes it when the handle
            // clears) so tray apps don't think a menu is still showing.
            _trayMenuItem = null;
            _trayMenuHandle = null;
            _trayMenuStack = [];
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
        // Tray menus nest: pop one level per Escape, then land on the tray
        // list, then the main menu.
        if (submenu === "traymenu") {
            query = "";
            if (_trayMenuStack.length > 0) {
                _trayMenuHandle = _trayMenuStack[_trayMenuStack.length - 1];
                _trayMenuStack = _trayMenuStack.slice(0, -1);
                results = _trayMenuToResults();
            } else {
                submenu = "tray";
                _trayMenuItem = null;
                _trayMenuHandle = null;
                results = _trayToResults();
            }
            selectedIndex = 0;
            return true;
        }
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
            } else if (result._data === "wifi") {
                Services.Network.scan();
                results = _wifiToResults();
                selectedIndex = 0;
            } else if (result._data === "bluetooth") {
                Services.Bluetooth.refresh();
                results = _btToResults();
                selectedIndex = 0;
            } else if (result._data === "audio") {
                results = _audioToResults();
                selectedIndex = 0;
            } else if (result._data === "tray") {
                results = _trayToResults();
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
        // Enter mirrors the popout's row semantics: connected → disconnect,
        // saved → connect, unknown → impala (password entry lives there,
        // same punt as the popout's manage row).
        case "wifi": {
            const w = result._data;
            if (w.connecting) return;
            visible = false;
            if (w.connected) Services.Network.disconnect();
            else if (w.known) Services.Network.connect(w.ssid);
            else _execTracked(["ghostty", "-e", "impala"]);
            return;
        }
        case "bt": {
            const d = result._data;
            visible = false;
            if (d.connected) Services.Bluetooth.disconnectDevice(d.address);
            else Services.Bluetooth.connectDevice(d.address);
            return;
        }
        // Stays open: the powered-change Connections swaps the off-row for
        // the device list in place.
        case "btpower":
            Services.Bluetooth.togglePower();
            return;
        case "sink":
            Services.Audio.setSink(result._data);
            visible = false;
            return;
        case "trayapp":
            if (!result._data.hasMenu) {
                visible = false;
                result._data.activate();
                return;
            }
            _debounce.stop();
            submenu = "traymenu";
            query = "";
            _trayMenuStack = [];
            _trayMenuItem = result._data;
            _trayMenuHandle = result._data.menu ?? null;
            results = _trayMenuToResults();
            selectedIndex = 0;
            return;
        case "trayactivate":
            visible = false;
            result._data.activate();
            return;
        case "traymenu": {
            const e = result._data;
            if (!e.enabled) return;
            if (e.hasChildren) {
                _debounce.stop();
                _trayMenuStack = [..._trayMenuStack, _trayMenuHandle];
                _trayMenuHandle = e;
                query = "";
                results = _trayMenuToResults();
                selectedIndex = 0;
                return;
            }
            visible = false;
            e.triggered();
            return;
        }
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

    function _placeholder(name, materialIcon): var {
        return [{ type: "placeholder", name: name, subtitle: "", icon: "", materialIcon: materialIcon, score: 0, _data: "" }];
    }

    // Shared submenu-list filter: every term must appear in name+subtitle.
    // Placeholders are dropped so "No devices" never matches a search.
    function _filterRows(rows, terms): var {
        return rows.filter(r => r.type !== "placeholder"
            && terms.every(t => (r.name + " " + r.subtitle).toLowerCase().includes(t)));
    }

    function _wifiToResults(): var {
        const out = [];
        const nets = Services.Network.networks;
        for (let i = 0; i < nets.count; i++) {
            const n = nets.get(i);
            const connecting = Services.Network.connectingTo === n.ssid;
            let subtitle;
            if (n.connected) subtitle = "Connected";
            else if (connecting) subtitle = "Connecting…";
            else if (n.known) subtitle = "Saved";
            else subtitle = (n.security ? n.security + " · " : "") + "via impala";
            out.push({
                type: "wifi",
                name: n.ssid,
                subtitle: subtitle,
                icon: "",
                materialIcon: ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar",
                               "network_wifi_3_bar", "signal_wifi_4_bar"][Math.min(n.signal, 4)],
                score: 0,
                _data: { ssid: n.ssid, connected: n.connected, known: n.known, connecting: connecting },
            });
        }
        if (out.length === 0)
            return _placeholder(Services.Network.scanning ? "Scanning…" : "No networks found", "wifi_find");
        return out;
    }

    function _btToResults(): var {
        if (!Services.Bluetooth.powered)
            return [{ type: "btpower", name: "Bluetooth is off", subtitle: "Turn on", icon: "",
                      materialIcon: "bluetooth_disabled", score: 0, _data: "" }];
        const out = [];
        const devs = Services.Bluetooth.devices;
        for (let i = 0; i < devs.count; i++) {
            const d = devs.get(i);
            let subtitle = "";
            if (d.connecting) subtitle = "Connecting…";
            else if (d.disconnecting) subtitle = "Disconnecting…";
            else if (d.connected) subtitle = d.batteryAvailable
                ? "Connected · " + Math.round(d.battery * 100) + "%" : "Connected";
            else if (d.paired) subtitle = "Paired";
            const ic = d.icon || "";
            let mi = "bluetooth";
            if (ic.includes("headset") || ic.includes("headphone")) mi = "headphones";
            else if (ic.includes("audio")) mi = "speaker";
            else if (ic.includes("mouse")) mi = "mouse";
            else if (ic.includes("keyboard")) mi = "keyboard";
            else if (ic.includes("phone")) mi = "smartphone";
            out.push({
                type: "bt",
                name: d.name,
                subtitle: subtitle,
                icon: "",
                materialIcon: mi,
                score: 0,
                _data: { address: d.address, connected: d.connected },
            });
        }
        if (out.length === 0)
            return _placeholder("No devices", "bluetooth_searching");
        return out;
    }

    function _audioToResults(): var {
        const out = [];
        for (const node of Services.Audio.sinks) {
            const isDefault = node === Services.Audio.sink;
            const desc = node.description || node.nickname || node.name || "Unknown";
            const dl = desc.toLowerCase();
            let mi = "volume_up";
            if (dl.includes("headphone") || dl.includes("headset")) mi = "headphones";
            else if (dl.includes("hdmi") || dl.includes("monitor") || dl.includes("display")) mi = "monitor";
            else if (dl.includes("bluetooth") || dl.includes("a2dp")) mi = "bluetooth";
            out.push({
                type: "sink",
                name: desc,
                subtitle: isDefault ? "Active" : "",
                icon: "",
                materialIcon: mi,
                score: 0,
                _data: node,
            });
        }
        if (out.length === 0)
            return _placeholder("No output devices", "volume_off");
        return out;
    }

    function _trayToResults(): var {
        const out = [];
        for (const t of SystemTray.items.values) {
            let title = t.title || t.tooltipTitle || t.id || "?";
            if (title === t.id)
                title = title.split("_")[0].charAt(0).toUpperCase() + title.split("_")[0].slice(1);
            const icon = t.icon ?? "";
            out.push({
                type: "trayapp",
                name: title,
                subtitle: t.hasMenu ? "" : "activates",
                icon: "",
                materialIcon: "grid_view",
                // Tray icons are full image URLs, not theme names — rendered
                // directly by LauncherPanel via _iconUrl (iconPath would fail).
                _iconUrl: icon.includes("?path=") ? "image://icon/" + t.id : icon,
                score: 0,
                _data: t,
            });
        }
        if (out.length === 0)
            return _placeholder("Tray is empty", "grid_view");
        return out;
    }

    function _trayMenuToResults(): var {
        const out = [];
        // Top level of an item that also supports a primary click: expose it —
        // it's the only keyboard path to "left-click the tray icon".
        if (_trayMenuStack.length === 0 && _trayMenuItem && !_trayMenuItem.onlyMenu) {
            out.push({ type: "trayactivate", name: "Activate", subtitle: "primary click", icon: "",
                       materialIcon: "open_in_new", score: 0, _data: _trayMenuItem });
        }
        for (const e of _trayMenuOpener.children?.values ?? []) {
            if (e.isSeparator) continue;
            let mi = "arrow_right";
            if (e.buttonType === 1) mi = e.checkState === 2 ? "check_box" : "check_box_outline_blank";
            else if (e.buttonType === 2) mi = e.checkState === 2 ? "radio_button_checked" : "radio_button_unchecked";
            else if (e.hasChildren) mi = "folder_open";
            out.push({
                type: "traymenu",
                name: e.text || "(unnamed)",
                subtitle: e.hasChildren ? "›" : (e.enabled ? "" : "disabled"),
                icon: "",
                materialIcon: mi,
                score: 0,
                _data: e,
            });
        }
        if (out.length === 0)
            return _placeholder("No menu items", "menu");
        return out;
    }

    // Submenu/wallpaper entries from the main menu, scored into the unified
    // search — "wifi<Enter>" should open the Wi-Fi list without scrolling.
    function _filterSubmenus(terms): var {
        const out = [];
        for (const m of Services.LauncherProviders.mainItems) {
            if (m.type !== "submenu" && m.type !== "wallpaper") continue;
            const score = _score(terms, m.name.toLowerCase(),
                                 (m.keywords ?? []).join(" "), [2.5, 1.5, 0.5]);
            if (score > 0)
                out.push(Object.assign({}, m, { score: score }));
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
            } else if (submenu === "wifi") {
                results = _wifiToResults();
            } else if (submenu === "bluetooth") {
                results = _btToResults();
            } else if (submenu === "audio") {
                results = _audioToResults();
            } else if (submenu === "tray") {
                results = _trayToResults();
            } else if (submenu === "traymenu") {
                results = _trayMenuToResults();
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
        if (submenu === "wifi") {
            results = _filterRows(_wifiToResults(), terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "bluetooth") {
            results = _filterRows(_btToResults(), terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "audio") {
            results = _filterRows(_audioToResults(), terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "tray") {
            results = _filterRows(_trayToResults(), terms);
            selectedIndex = 0;
            return;
        }
        if (submenu === "traymenu") {
            results = _filterRows(_trayMenuToResults(), terms);
            selectedIndex = 0;
            return;
        }

        let all = [
            ..._filterApps(terms),
            ..._filterWindows(terms),
            ..._filterKeybinds(terms),
            ..._filterActions(terms),
            ..._filterSubmenus(terms),
            ..._filterClipboard(terms),
        ];
        all.sort((a, b) => b.score - a.score);
        results = all.slice(0, 20);
        selectedIndex = 0;
    }
}
