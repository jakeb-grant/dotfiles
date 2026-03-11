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

    // All physical audio output devices (sinks, not app streams)
    readonly property var sinks: {
        const result = [];
        const nodes = Pipewire.nodes.values;
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n.isSink && !n.isStream) result.push(n);
        }
        return result;
    }

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

    function setSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    PwObjectTracker {
        objects: root.sinks.concat([root.sink])
    }
}
