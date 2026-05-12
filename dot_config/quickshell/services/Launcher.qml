pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.utils as Utils

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
    property var _themes: []
    property var _themeBuffer: []

    // ── Static data ──

    readonly property var _keybinds: (function() {
        const items = [
            { name: "Terminal",            shortcut: "Super + Return",        command:  "ghostty",                                            keywords: ["ghostty","shell"] },
            { name: "Browser",             shortcut: "Super + Shift + B",     command:  "xdg-open https://",                                  keywords: ["firefox","web"] },
            { name: "File Manager",        shortcut: "Super + Shift + F",     command:  "pane-fm",                                            keywords: ["panefm","files"] },
            { name: "Editor",              shortcut: "Super + Shift + Z",     command:  "zeditor",                                            keywords: ["zed","code"] },
            { name: "Close Window",        shortcut: "Super + W",             dispatch: 'hl.dsp.window.close()',                              keywords: ["kill","quit"] },
            { name: "Toggle Floating",     shortcut: "Super + T",             dispatch: 'hl.dsp.window.float({ action = "toggle" })',         keywords: ["tile","float"] },
            { name: "Fullscreen",          shortcut: "Super + F",             dispatch: 'hl.dsp.window.fullscreen()',                         keywords: ["maximize"] },
            { name: "Pin Window",          shortcut: "Super + O",             dispatch: 'hl.dsp.window.pin()',                                keywords: ["sticky"] },
            { name: "Next Workspace",      shortcut: "Super + Tab",           dispatch: 'hl.dsp.focus({ workspace = "e+1" })',                keywords: ["switch"] },
            { name: "Previous Workspace",  shortcut: "Super + Shift + Tab",   dispatch: 'hl.dsp.focus({ workspace = "e-1" })',                keywords: ["switch"] },
            { name: "Last Workspace",      shortcut: "Super + Ctrl + Tab",    dispatch: 'hl.dsp.focus({ workspace = "previous" })',           keywords: ["switch","previous","back"] },
            { name: "Scratchpad",          shortcut: "Super + S",             dispatch: 'hl.dsp.workspace.toggle_special("magic")',           keywords: ["hidden","stash"] },
            { name: "Dismiss Notification",shortcut: "Super + ,",             dispatch: 'hl.dsp.global("quickshell:notif-dismiss")',          keywords: ["close","clear"] },
            { name: "Dismiss All",         shortcut: "Super + Shift + ,",     dispatch: 'hl.dsp.global("quickshell:notif-dismiss-all")',      keywords: ["clear","close"] },
            { name: "Screenshot (Area)",   shortcut: "Print",                 command:  "sh -c 'f=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" \"$f\" && wl-copy < \"$f\"'", keywords: ["capture","snip"] },
            { name: "Screenshot (Full)",   shortcut: "Shift + Print",         command:  "sh -c 'f=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && mkdir -p ~/Pictures/Screenshots && grim \"$f\" && wl-copy < \"$f\"'", keywords: ["capture","screen"] },
            { name: "Color Picker",        shortcut: "Super + Print",         command:  "hyprpicker -a",                                      keywords: ["pick","eyedropper"] },
            { name: "Lock Screen",         shortcut: "Super + L",             dispatch: 'hl.dsp.global("quickshell:lock")',                   keywords: ["lock"] },
            { name: "Toggle Bar Mode",     shortcut: "Super + Shift + T",     command:  "toggle-bar-mode",                                    keywords: ["sidebar","topbar","bar","layout","swap"] },
            { name: "Logout",              shortcut: "",                      dispatch: 'hl.dsp.exit()',                                      keywords: ["exit"] },
            { name: "Suspend",             shortcut: "",                      command:  "systemctl suspend",                                  keywords: ["sleep"] },
            { name: "Reboot",              shortcut: "",                      command:  "systemctl reboot",                                   keywords: ["restart"] },
            { name: "Shutdown",            shortcut: "",                      command:  "systemctl poweroff",                                 keywords: ["poweroff"] },
        ];
        for (const d of [{key:"Left",dir:"l"},{key:"Right",dir:"r"},{key:"Up",dir:"u"},{key:"Down",dir:"d"}]) {
            items.push({ name: "Swap Window " + d.key, shortcut: "Super + Shift + " + d.key,
                         dispatch: 'hl.dsp.window.swap({ direction = "' + d.dir + '" })', keywords: ["move","swap"] });
        }
        for (const r of [{name:"Wider",sc:"=",x:50,y:0,kw:"grow"},{name:"Narrower",sc:"-",x:-50,y:0,kw:"shrink"},
                         {name:"Taller",sc:"Shift + =",x:0,y:50,kw:"grow"},{name:"Shorter",sc:"Shift + -",x:0,y:-50,kw:"shrink"}]) {
            items.push({ name: "Resize " + r.name, shortcut: "Super + " + r.sc,
                         dispatch: 'hl.dsp.window.resize({ x = ' + r.x + ', y = ' + r.y + ', relative = true })', keywords: [r.kw,"resize"] });
        }
        return items;
    })()

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
        { type: "submenu", name: "Themes", subtitle: "", icon: "", materialIcon: "palette", score: 0, _data: "themes" },
        { type: "wallpaper", name: "Wallpapers", subtitle: "", icon: "", materialIcon: "wallpaper", score: 0, _data: "" },
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
                _data: kb.dispatch ?? kb.command,
                _isDispatch: !!kb.dispatch,
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

    Process {
        id: _themeScanProc
        onRunningChanged: {
            if (running) {
                root._themeBuffer = [];
            } else {
                root._themes = root._themeBuffer;
                root._themeBuffer = [];
                if (root._submenu === "themes")
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
        _themeScanProc.command = ["python3", "-c",
            "import json, os\n" +
            "d = '" + Utils.Theme.palettePath + "'\n" +
            "for f in sorted(os.listdir(d)):\n" +
            "    if f == 'active.json' or not f.endswith('.json'): continue\n" +
            "    try:\n" +
            "        p = json.load(open(os.path.join(d, f)))\n" +
            "        name = p.get('_name','')\n" +
            "        if not name: continue\n" +
            "        qs = p.get('_quickshell', {})\n" +
            "        accent = qs.get('accent', p.get('blue',''))\n" +
            "        sw = '|'.join([p.get('base',''), accent, p.get('red',''), p.get('green',''), p.get('yellow',''), p.get('mauve','')])\n" +
            "        print(f'{f}|{name}|{sw}')\n" +
            "    except: pass\n"];
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
            if (root._submenu === "themes")
                root.results = root._themesToResults();
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
            } else if (result._data === "themes") {
                _scanThemes();
                results = _themesToResults();
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
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + result._data + '" })');
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
        case "theme":
            _switchTheme(result._data);
            return;
        case "wallpaper":
            _debounce.stop();
            _submenu = "wallpaper";
            query = "";
            Wallpaper.refreshForLauncher();
            return;
        case "keybind":
        case "action":
            // Close first so interactive tools (slurp, etc.) can grab the screen
            visible = false;
            if (result._isDispatch) {
                Hyprland.dispatch(result._data);
            } else {
                Quickshell.execDetached(["sh", "-c", result._data]);
            }
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
                    _data: kb.dispatch ?? kb.command,
                    _isDispatch: !!kb.dispatch,
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

    function _filterClipboard(terms): var {
        const out = [];
        for (const entry of _clipboardEntries) {
            const text = entry.text.toLowerCase();
            let match = true;
            for (const term of terms) {
                if (!text.includes(term)) { match = false; break; }
            }
            if (match) {
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
            if (_submenu === "keybinds") {
                results = _allKeybindItems;
            } else if (_submenu === "clipboard") {
                results = _clipboardToResults(_clipboardEntries);
            } else if (_submenu === "themes") {
                results = _themesToResults();
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
        if (_submenu === "themes") {
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
