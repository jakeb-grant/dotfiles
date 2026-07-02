pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Icon names that exist in installed icon themes. Populated once at startup —
    // tray menus check membership on every open, so this must not rescan per use.
    property var icons: ({})

    Process {
        running: true
        // Collect all icon filenames across all installed themes
        command: ["sh", "-c", "find /usr/share/icons -type f \\( -name '*.svg' -o -name '*.png' \\) -printf '%f\\n' | sort -u"]

        stdout: SplitParser {
            onRead: data => {
                const name = data.trim().replace(/\.(svg|png)$/, "");
                if (name !== "") root.icons[name] = true;
            }
        }
    }
}
