pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var categoryIcons: ({
        WebBrowser: "web",
        Printing: "print",
        Security: "security",
        Network: "chat",
        Archiving: "archive",
        Compression: "archive",
        Development: "code",
        IDE: "code",
        TextEditor: "edit_note",
        Audio: "music_note",
        Music: "music_note",
        Player: "music_note",
        Recorder: "mic",
        Game: "sports_esports",
        FileTools: "files",
        FileManager: "files",
        Filesystem: "files",
        FileTransfer: "files",
        Settings: "settings",
        DesktopSettings: "settings",
        HardwareSettings: "settings",
        TerminalEmulator: "terminal",
        ConsoleOnly: "terminal",
        Utility: "build",
        Monitor: "monitor_heart",
        Midi: "graphic_eq",
        Mixer: "graphic_eq",
        AudioVideoEditing: "video_settings",
        AudioVideo: "music_video",
        Video: "videocam",
        Building: "construction",
        Graphics: "photo_library",
        "2DGraphics": "photo_library",
        RasterGraphics: "photo_library",
        TV: "tv",
        System: "host",
        Office: "content_paste"
    })

    function getAppCategoryIcon(name: string, fallback: string): string {
        const categories = DesktopEntries.heuristicLookup(name)?.categories;

        if (categories)
            for (const [key, value] of Object.entries(root.categoryIcons))
                if (categories.includes(key))
                    return value;
        return fallback;
    }
}
