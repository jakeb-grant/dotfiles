pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services as Services

Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property int cpuTemp: 0
    property int diskPercent: 0
    property string diskUsed: ""
    property string diskTotal: ""

    // GPU (optional — auto-detected)
    property bool gpuAvailable: false
    property int gpuPercent: 0
    property int gpuTemp: 0
    property int gpuMemPercent: 0
    property string gpuMemUsed: ""
    property string gpuMemTotal: ""
    property string gpuType: "" // "nvidia" or "amd"

    property real _prevIdle: 0
    property real _prevTotal: 0
    property int _lineIndex: 0

    Process {
        id: statsProc
        command: ["sh", "-c",
            "head -1 /proc/stat; " +
            "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " +
            "found=0; for z in /sys/class/thermal/thermal_zone*/type; do t=$(cat \"$z\"); case \"$t\" in x86_pkg_temp|coretemp|k10temp) cat \"${z%type}temp\"; found=1; break;; esac; done; [ $found -eq 0 ] && echo 0; " +
            "df -BG --output=used,size / | tail -1"
        ]
        onRunningChanged: {
            if (running)
                root._lineIndex = 0;
        }
        stdout: SplitParser {
            onRead: data => root._parseLine(data)
        }
    }

    function _parseLine(line: string): void {
        const idx = _lineIndex++;

        if (idx === 0) {
            const parts = line.trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + (parts[4] ?? 0);
            let total = 0;
            for (let i = 0; i < parts.length; i++) total += parts[i];

            if (_prevTotal > 0) {
                const dTotal = total - _prevTotal;
                const dIdle = idle - _prevIdle;
                cpuPercent = dTotal > 0 ? Math.round((1 - dIdle / dTotal) * 100) : 0;
            }
            _prevIdle = idle;
            _prevTotal = total;
        } else if (idx <= 2) {
            const parts = line.trim().split(/\s+/);
            const kb = parseInt(parts[1]);
            if (parts[0].startsWith("MemTotal")) {
                memTotalGb = kb / 1048576;
            } else {
                const availGb = kb / 1048576;
                memUsedGb = memTotalGb - availGb;
                memPercent = memTotalGb > 0 ? Math.round(memUsedGb / memTotalGb * 100) : 0;
            }
        } else if (idx === 3) {
            cpuTemp = Math.round(parseInt(line.trim()) / 1000);
        } else if (idx === 4) {
            const parts = line.trim().split(/\s+/);
            diskUsed = parts[0];
            diskTotal = parts[1];
            const used = parseInt(parts[0]);
            const total = parseInt(parts[1]);
            diskPercent = total > 0 ? Math.round(used / total * 100) : 0;
        }
    }

    // ── GPU polling ──
    Process {
        id: gpuDetect
        command: ["sh", "-c",
            "if command -v nvidia-smi >/dev/null 2>&1; then echo nvidia; " +
            "elif [ -f /sys/class/drm/card1/device/gpu_busy_percent ]; then echo amd; " +
            "else echo none; fi"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const t = data.trim();
                if (t !== "none") {
                    root.gpuType = t;
                    root.gpuAvailable = true;
                }
            }
        }
    }

    Process {
        id: gpuProc
        command: gpuType === "nvidia"
            ? ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total",
               "--format=csv,noheader,nounits"]
            : ["sh", "-c",
                "cat /sys/class/drm/card1/device/gpu_busy_percent; " +
                "cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null || echo 0; " +
                "cat /sys/class/drm/card1/device/mem_info_vram_used 2>/dev/null || echo 0; " +
                "cat /sys/class/drm/card1/device/mem_info_vram_total 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => root._parseGpu(data)
        }
    }

    property int _gpuLineIndex: 0

    function _parseGpu(line: string): void {
        if (gpuType === "nvidia") {
            // Single CSV line: utilization, temp, mem_used, mem_total
            const parts = line.trim().split(/,\s*/);
            if (parts.length >= 4) {
                gpuPercent = parseInt(parts[0]);
                gpuTemp = parseInt(parts[1]);
                const used = parseInt(parts[2]);
                const total = parseInt(parts[3]);
                gpuMemUsed = used >= 1024 ? (used / 1024).toFixed(1) + " GB" : used + " MB";
                gpuMemTotal = total >= 1024 ? (total / 1024).toFixed(1) + " GB" : total + " MB";
                gpuMemPercent = total > 0 ? Math.round(used / total * 100) : 0;
            }
        } else {
            // AMD: 4 lines
            const idx = _gpuLineIndex++;
            const val = parseInt(line.trim());
            if (idx === 0) gpuPercent = val;
            else if (idx === 1) gpuTemp = Math.round(val / 1000);
            else if (idx === 2) {
                const mb = val / 1048576;
                gpuMemUsed = mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : Math.round(mb) + " MB";
            } else if (idx === 3) {
                const mb = val / 1048576;
                gpuMemTotal = mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : Math.round(mb) + " MB";
                const used = parseInt(gpuMemUsed);
                gpuMemPercent = mb > 0 ? Math.round(parseInt(gpuMemUsed) / Math.round(mb) * 100) : 0;
            }
        }
    }

    readonly property bool _active: Services.Popout.currentName === "system"

    on_ActiveChanged: {
        if (_active) {
            statsProc.running = true;
            if (gpuAvailable) {
                _gpuLineIndex = 0;
                gpuProc.running = true;
            }
        }
    }

    Timer {
        interval: 3000
        running: root._active
        repeat: true
        onTriggered: {
            statsProc.running = true;
            if (root.gpuAvailable) {
                root._gpuLineIndex = 0;
                gpuProc.running = true;
            }
        }
    }
}
