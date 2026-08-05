pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Icon names that exist in installed icon themes. Populated once at startup —
    // tray menus check membership on every open, so this must not rescan per use.
    property var icons: ({})

    // Bumped when the scan finishes. `icons` is mutated in place, which emits no
    // change signal, so bindings that test membership must read `revision` to get
    // re-evaluated once the cache is actually populated.
    property int revision: 0

    // Membership test for a theme icon name. Callers gate on this instead of
    // Quickshell.iconPath(name, true): the `check` argument runs QIcon::fromTheme
    // on the GUI thread, which races the icon image provider's QIcon use on the
    // QQuickPixmapReader thread and aborts the process.
    function has(name: string): bool {
        return name.length > 0 && root.icons[name] === true;
    }

    Process {
        running: true
        // Every directory QIcon::fromTheme would search, so membership here matches
        // what the icon provider can actually resolve — a narrower scan would hide
        // icons that currently render.
        command: ["sh", "-c", "find /usr/share/icons /usr/share/pixmaps \"$HOME/.local/share/icons\" /var/lib/flatpak/exports/share/icons -type f \\( -name '*.svg' -o -name '*.png' -o -name '*.xpm' \\) -printf '%f\\n' 2>/dev/null | sort -u"]

        stdout: SplitParser {
            onRead: data => {
                const name = data.trim().replace(/\.(svg|png|xpm)$/, "");
                if (name !== "") root.icons[name] = true;
            }
        }

        onExited: root.revision++
    }
}
