pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// System identity + package facts for SystemPopout. Statics are fetched once
// per shell start; uptime/package counts re-fetch via refresh() on popout open.
Singleton {
    id: root

    // Static per boot
    property string kernel: ""
    property string hostname: ""
    property string shell: ""

    // Refreshed on demand
    property string uptime: ""
    property string pkgNative: ""
    property string pkgAur: ""

    Process {
        id: staticProc
        // One line: kernel|hostname|shell
        command: ["sh", "-c", "echo \"$(uname -r)|$(cat /etc/hostname)|$(basename \"$SHELL\")\""]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length < 3) return;
                root.kernel = parts[0].trim();
                root.hostname = parts[1].trim();
                root.shell = parts[2].trim();
            }
        }
    }

    function refresh(): void {
        refreshProc.running = true;
    }

    Process {
        id: refreshProc
        // One line: uptime|native count|AUR count
        command: ["sh", "-c", "echo \"$(uptime -p | sed 's/up //')|$(pacman -Qn | wc -l)|$(pacman -Qm | wc -l)\""]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length < 3) return;
                root.uptime = parts[0].trim();
                root.pkgNative = parts[1].trim();
                root.pkgAur = parts[2].trim();
            }
        }
    }
}
