pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0
    property var results: []
    property var activeScreen: null

    readonly property string mode: query.startsWith("=") ? "calc" : "unified"
    readonly property string effectiveQuery: mode === "calc" ? query.substring(1).trim() : query

    property string _submenu: ""
    property var _clipboardEntries: []

    // ── Static data ──

    readonly property var _keybinds: [
        { name: "Terminal", shortcut: "Super + Return", command: "ghostty", keywords: ["ghostty","shell"] },
        { name: "Browser", shortcut: "Super + Shift + B", command: "xdg-open https://", keywords: ["firefox","web"] },
        { name: "File Manager", shortcut: "Super + Shift + F", command: "ghostty -e yazi", keywords: ["yazi","files"] },
        { name: "Editor", shortcut: "Super + Shift + Z", command: "zeditor", keywords: ["zed","code"] },
        { name: "Close Window", shortcut: "Super + W", command: "hyprctl dispatch killactive", keywords: ["kill","quit"] },
        { name: "Toggle Floating", shortcut: "Super + T", command: "hyprctl dispatch togglefloating", keywords: ["tile","float"] },
        { name: "Fullscreen", shortcut: "Super + F", command: "hyprctl dispatch fullscreen", keywords: ["maximize"] },
        { name: "Pin Window", shortcut: "Super + O", command: "hyprctl dispatch pin", keywords: ["sticky"] },
        { name: "Swap Window Left", shortcut: "Super + Shift + Left", command: "hyprctl dispatch swapwindow l", keywords: ["move","swap"] },
        { name: "Swap Window Right", shortcut: "Super + Shift + Right", command: "hyprctl dispatch swapwindow r", keywords: ["move","swap"] },
        { name: "Swap Window Up", shortcut: "Super + Shift + Up", command: "hyprctl dispatch swapwindow u", keywords: ["move","swap"] },
        { name: "Swap Window Down", shortcut: "Super + Shift + Down", command: "hyprctl dispatch swapwindow d", keywords: ["move","swap"] },
        { name: "Resize Wider", shortcut: "Super + =", command: "hyprctl dispatch resizeactive 50 0", keywords: ["grow","resize"] },
        { name: "Resize Narrower", shortcut: "Super + -", command: "hyprctl dispatch resizeactive -50 0", keywords: ["shrink","resize"] },
        { name: "Resize Taller", shortcut: "Super + Shift + =", command: "hyprctl dispatch resizeactive 0 50", keywords: ["grow","resize"] },
        { name: "Resize Shorter", shortcut: "Super + Shift + -", command: "hyprctl dispatch resizeactive 0 -50", keywords: ["shrink","resize"] },
        { name: "Next Workspace", shortcut: "Super + Tab", command: "hyprctl dispatch workspace e+1", keywords: ["switch"] },
        { name: "Previous Workspace", shortcut: "Super + Shift + Tab", command: "hyprctl dispatch workspace e-1", keywords: ["switch"] },
        { name: "Last Workspace", shortcut: "Super + Ctrl + Tab", command: "hyprctl dispatch workspace previous", keywords: ["switch","previous","back"] },
        { name: "Scratchpad", shortcut: "Super + S", command: "hyprctl dispatch togglespecialworkspace magic", keywords: ["hidden","stash"] },
        { name: "Dismiss Notification", shortcut: "Super + ,", command: "hyprctl dispatch global quickshell:notif-dismiss", keywords: ["close","clear"] },
        { name: "Dismiss All", shortcut: "Super + Shift + ,", command: "hyprctl dispatch global quickshell:notif-dismiss-all", keywords: ["clear","close"] },
        { name: "Notification Panel", shortcut: "Super + Alt + ,", command: "hyprctl dispatch global quickshell:notif-panel", keywords: ["center"] },
        { name: "Screenshot (Area)", shortcut: "Print", command: "grim -g \"$(slurp)\" - | wl-copy", keywords: ["capture","snip"] },
        { name: "Screenshot (Full)", shortcut: "Shift + Print", command: "grim - | wl-copy", keywords: ["capture","screen"] },
        { name: "Color Picker", shortcut: "Super + Print", command: "hyprpicker -a", keywords: ["pick","eyedropper"] },
        { name: "Toggle Waybar", shortcut: "Super + Shift + Space", command: "killall -SIGUSR1 waybar", keywords: ["bar","hide"] },
        { name: "Lock Screen", shortcut: "Super + L", command: "hyprlock", keywords: ["lock"] },
        { name: "Logout", shortcut: "", command: "hyprctl dispatch exit", keywords: ["exit"] },
        { name: "Suspend", shortcut: "", command: "systemctl suspend", keywords: ["sleep"] },
        { name: "Reboot", shortcut: "", command: "systemctl reboot", keywords: ["restart"] },
        { name: "Shutdown", shortcut: "", command: "systemctl poweroff", keywords: ["poweroff"] },
    ]

    readonly property var _actions: [
        { name: "Upkeep", icon: "", materialIcon: "system_update", command: "ghostty -e upkeep", keywords: ["update","upgrade","rebuild","maintenance"] },
        { name: "Display", icon: "", materialIcon: "monitor", command: "ghostty -e hyprpier mgr", keywords: ["monitor","screen","resolution"] },
        { name: "About", icon: "", materialIcon: "info", command: "ghostty -e bash -c 'fastfetch; read -p \"Press Enter to close...\"'", keywords: ["info","specs","hardware","fastfetch"] },
        { name: "Process Manager", icon: "", materialIcon: "monitoring", command: "ghostty -e btop", keywords: ["htop","btop","cpu","memory","task"] },
        { name: "Windows VM", icon: "", materialIcon: "computer", command: "win-vm", keywords: ["vm","virtual","machine","windows"] },
    ]

    readonly property var _mainItems: [
        { type: "submenu", name: "Keybinds", subtitle: "", icon: "", materialIcon: "keyboard", score: 0, _data: "keybinds" },
        { type: "submenu", name: "Clipboard", subtitle: "", icon: "", materialIcon: "content_paste", score: 0, _data: "clipboard" },
        { type: "action", name: "Upkeep", subtitle: "", icon: "", materialIcon: "system_update", score: 0, _data: "ghostty -e upkeep" },
        { type: "action", name: "Display", subtitle: "", icon: "", materialIcon: "monitor", score: 0, _data: "ghostty -e hyprpier mgr" },
        { type: "action", name: "About", subtitle: "", icon: "", materialIcon: "info", score: 0, _data: "ghostty -e bash -c 'fastfetch; read -p \"Press Enter to close...\"'" },
        { type: "action", name: "Windows VM", subtitle: "", icon: "", materialIcon: "computer", score: 0, _data: "win-vm" },
    ]

    readonly property var _allKeybindItems: {
        const out = [];
        for (const kb of _keybinds) {
            out.push({
                type: "keybind",
                name: kb.name,
                subtitle: kb.shortcut,
                icon: "",
                materialIcon: "keyboard",
                score: 0,
                _data: kb.command,
            });
        }
        return out;
    }

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

    onVisibleChanged: {
        if (visible) {
            query = "";
            selectedIndex = 0;
            _submenu = "";
            results = _mainItems;
            _clipboardEntries = [];
            _clipListProc.running = true;
            activeScreen = Hyprland.focusedMonitor?.name ?? "";
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

    function toggle(): void {
        visible = !visible;
    }

    function goBack(): bool {
        if (_submenu !== "") {
            _submenu = "";
            query = "";
            results = _mainItems;
            selectedIndex = 0;
            return true;
        }
        return false;
    }

    function launch(result): void {
        switch (result.type) {
        case "submenu":
            _debounce.stop();
            _submenu = result._data;
            query = "";
            if (result._data === "keybinds") {
                results = _allKeybindItems;
                selectedIndex = 0;
            } else if (result._data === "clipboard") {
                results = _clipboardToResults(_clipboardEntries);
                selectedIndex = 0;
            }
            return;
        case "app":
            if (result._data.runInTerminal) {
                Quickshell.execDetached(["ghostty", "-e", ...result._data.command]);
            } else {
                result._data.execute();
            }
            break;
        case "window":
            Hyprland.dispatch("focuswindow address:" + result._data);
            break;
        case "calc":
            _copyProc.running = false;
            _copyProc.command = ["wl-copy", result.subtitle];
            _copyProc.running = true;
            break;
        case "clipboard":
            _clipDecodeProc.running = false;
            _clipDecodeProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", result._data];
            _clipDecodeProc.running = true;
            break;
        case "keybind":
        case "action":
            // Close first so interactive tools (slurp, etc.) can grab the screen
            visible = false;
            Quickshell.execDetached(["sh", "-c", result._data]);
            return;
        }
        visible = false;
    }

    // ── Provider functions ──

    function _filterApps(terms): var {
        const apps = DesktopEntries.applications.values;
        const out = [];
        for (const app of apps) {
            const name = (app.name ?? "").toLowerCase();
            const comment = (app.comment ?? "").toLowerCase();
            const cats = (app.categories ?? []).join(" ").toLowerCase();
            let score = 0;
            for (const term of terms) {
                if (name.startsWith(term)) score += 3;
                else if (name.includes(term)) score += 2;
                else if (comment.includes(term) || cats.includes(term)) score += 1;
                else { score = 0; break; }
            }
            if (score > 0) {
                const lengthPenalty = name.length / 100;
                out.push({
                    type: "app",
                    name: app.name ?? "",
                    subtitle: app.comment ?? "",
                    icon: app.icon ?? "",
                    materialIcon: "",
                    score: score - lengthPenalty,
                    _data: app,
                });
            }
        }
        return out;
    }

    function _filterWindows(terms): var {
        const toplevels = Hyprland.toplevels?.values ?? [];
        const out = [];
        for (const t of toplevels) {
            const title = (t.lastIpcObject?.title ?? "").toLowerCase();
            const cls = (t.lastIpcObject?.class ?? "").toLowerCase();
            const addr = t.lastIpcObject?.address ?? "";
            let score = 0;
            for (const term of terms) {
                if (title.startsWith(term)) score += 3;
                else if (title.includes(term)) score += 2;
                else if (cls.includes(term)) score += 1;
                else { score = 0; break; }
            }
            if (score > 0) {
                out.push({
                    type: "window",
                    name: t.lastIpcObject?.title ?? "",
                    subtitle: t.lastIpcObject?.class ?? "",
                    icon: "",
                    materialIcon: "desktop_windows",
                    score: score,
                    _data: addr,
                });
            }
        }
        return out;
    }

    function _filterKeybinds(terms): var {
        const out = [];
        for (const kb of _keybinds) {
            const name = kb.name.toLowerCase();
            const shortcut = kb.shortcut.toLowerCase();
            const kw = kb.keywords.join(" ");
            let score = 0;
            for (const term of terms) {
                if (name.startsWith(term)) score += 2.5;
                else if (name.includes(term)) score += 1.5;
                else if (shortcut.includes(term) || kw.includes(term)) score += 0.5;
                else { score = 0; break; }
            }
            if (score > 0) {
                out.push({
                    type: "keybind",
                    name: kb.name,
                    subtitle: kb.shortcut,
                    icon: "",
                    materialIcon: "keyboard",
                    score: score,
                    _data: kb.command,
                });
            }
        }
        return out;
    }

    function _filterActions(terms): var {
        const out = [];
        for (const act of _actions) {
            const name = act.name.toLowerCase();
            const kw = act.keywords.join(" ");
            let score = 0;
            for (const term of terms) {
                if (name.startsWith(term)) score += 2.5;
                else if (name.includes(term)) score += 1.5;
                else if (kw.includes(term)) score += 0.5;
                else { score = 0; break; }
            }
            if (score > 0) {
                out.push({
                    type: "action",
                    name: act.name,
                    subtitle: "",
                    icon: act.icon,
                    materialIcon: act.materialIcon ?? "",
                    score: score,
                    _data: act.command,
                });
            }
        }
        return out;
    }

    function _clipboardToResults(entries): var {
        const out = [];
        for (const entry of entries) {
            const display = entry.text.length > 80
                ? entry.text.substring(0, 80) + "…" : entry.text;
            out.push({
                type: "clipboard",
                name: display,
                subtitle: "",
                icon: "",
                materialIcon: "content_paste",
                score: 0,
                _data: entry.id,
            });
        }
        return out;
    }

    function _filterClipboard(terms): var {
        const out = [];
        for (const entry of _clipboardEntries) {
            const text = entry.text.toLowerCase();
            let match = true;
            for (const term of terms) {
                if (!text.includes(term)) { match = false; break; }
            }
            if (match) {
                const display = entry.text.length > 80
                    ? entry.text.substring(0, 80) + "…" : entry.text;
                out.push({
                    type: "clipboard",
                    name: display,
                    subtitle: "",
                    icon: "",
                    materialIcon: "content_paste",
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
            if (_submenu === "keybinds") {
                results = _allKeybindItems;
            } else if (_submenu === "clipboard") {
                results = _clipboardToResults(_clipboardEntries);
            } else {
                results = _mainItems;
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
        if (_submenu === "keybinds") {
            results = _filterKeybinds(terms);
            selectedIndex = 0;
            return;
        }
        if (_submenu === "clipboard") {
            results = _filterClipboard(terms);
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
