pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.services as Services

// Static launcher data — keybind/action tables and the main menu. The state
// machine, filtering, and dispatch live in Launcher.qml; this file is only
// edited to add or change entries.
Singleton {
    readonly property var keybinds: (function() {
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
            { name: "Screenshot (Area)",   shortcut: "Print",                 command:  "screenshot region",                                  keywords: ["capture","snip"] },
            // sleep: let the launcher's 300ms close animation finish so the
            // capture doesn't include the fading island (menu path only —
            // the real keybind has no launcher open)
            { name: "Screenshot (Full)",   shortcut: "Shift + Print",         command:  "sleep 0.4; screenshot full",                         keywords: ["capture","screen"] },
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

    readonly property var actions: [
        // special: "dnd" dispatches to Services.Notifications.toggleDnd() in
        // Launcher.launch() instead of running a command. Icon/subtitle
        // reference live state, making this whole array a binding that
        // re-evaluates on toggle.
        { name: "Do Not Disturb", icon: "", materialIcon: Services.Notifications.dnd ? "notifications_off" : "notifications",
          subtitle: Services.Notifications.dnd ? "On" : "", special: "dnd",
          keywords: ["dnd","notifications","silence","quiet","focus","mute"] },
        { name: "Upkeep", icon: "", materialIcon: "system_update", command: "ghostty -e upkeep", keywords: ["update","upgrade","rebuild","maintenance"] },
        { name: "Display", icon: "", materialIcon: "monitor", command: "ghostty -e hyprpier mgr", keywords: ["monitor","screen","resolution"] },
        { name: "About", icon: "", materialIcon: "info", command: "ghostty -e bash -c 'fastfetch; read -p \"Press Enter to close...\"'", keywords: ["info","specs","hardware","fastfetch"] },
        { name: "Process Manager", icon: "", materialIcon: "monitoring", command: "ghostty -e btop", keywords: ["htop","btop","cpu","memory","task"] },
        { name: "Windows VM", icon: "", materialIcon: "computer", command: "win-vm", keywords: ["vm","virtual","machine","windows"] },
    ]

    // keywords make submenu entries reachable from the unified search
    // (Launcher._filterSubmenus) — typing "wifi" beats scrolling the list.
    // Wi-Fi/Bluetooth/Audio subtitles bind live service state; the Tray entry
    // only exists while the tray has items (same condition as the bar slot).
    readonly property var mainItems: [
        { type: "submenu", name: "Keybinds", subtitle: "", icon: "", materialIcon: "keyboard", score: 0, _data: "keybinds", keywords: ["keybinds", "shortcuts", "hotkeys"] },
        { type: "submenu", name: "Clipboard", subtitle: "", icon: "", materialIcon: "content_paste", score: 0, _data: "clipboard", keywords: ["clipboard", "paste", "history"] },
        { type: "submenu", name: "Notifications", subtitle: "", icon: "", materialIcon: "notifications", score: 0, _data: "notifhistory", keywords: ["notifications", "history"] },
        { type: "submenu", name: "Wi-Fi", subtitle: Services.Network.state === "connected" ? Services.Network.ssid : "", icon: "", materialIcon: "wifi", score: 0, _data: "wifi", keywords: ["wifi", "network", "internet", "wireless"] },
        { type: "submenu", name: "Bluetooth", subtitle: Services.Bluetooth.connectedDevice?.name ?? "", icon: "", materialIcon: "bluetooth", score: 0, _data: "bluetooth", keywords: ["bluetooth", "bt", "pair", "device", "headphones"] },
        { type: "submenu", name: "Audio Output", subtitle: "", icon: "", materialIcon: "speaker", score: 0, _data: "audio", keywords: ["audio", "output", "sink", "sound", "speaker", "headphones"] },
        ...(SystemTray.items.values.length > 0
            ? [{ type: "submenu", name: "Tray", subtitle: "", icon: "", materialIcon: "grid_view", score: 0, _data: "tray", keywords: ["tray", "indicator", "status", "menu"] }]
            : []),
        { type: "submenu", name: "Themes", subtitle: "", icon: "", materialIcon: "palette", score: 0, _data: "themes", keywords: ["themes", "theme", "colors", "palette"] },
        { type: "wallpaper", name: "Wallpapers", subtitle: "", icon: "", materialIcon: "wallpaper", score: 0, _data: "", keywords: ["wallpapers", "wallpaper", "background"] },
        { type: "action", name: "Do Not Disturb", subtitle: Services.Notifications.dnd ? "On" : "", icon: "", materialIcon: Services.Notifications.dnd ? "notifications_off" : "notifications", score: 0, _data: "", _special: "dnd" },
        { type: "action", name: "Upkeep", subtitle: "", icon: "", materialIcon: "system_update", score: 0, _data: "ghostty -e upkeep" },
        { type: "action", name: "Display", subtitle: "", icon: "", materialIcon: "monitor", score: 0, _data: "ghostty -e hyprpier mgr" },
        { type: "action", name: "About", subtitle: "", icon: "", materialIcon: "info", score: 0, _data: "ghostty -e bash -c 'fastfetch; read -p \"Press Enter to close...\"'" },
        { type: "action", name: "Windows VM", subtitle: "", icon: "", materialIcon: "computer", score: 0, _data: "win-vm" },
    ]

    readonly property var keybindItems: {
        const out = [];
        for (const kb of keybinds) {
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
}
