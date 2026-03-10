pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property int volumePercent: Math.round(volume * 100)

    function incrementVolume(): void {
        if (sink?.audio)
            sink.audio.volume = Math.min(1.0, volume + 0.05);
    }

    function decrementVolume(): void {
        if (sink?.audio)
            sink.audio.volume = Math.max(0.0, volume - 0.05);
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
