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

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property string micIcon: sourceMuted ? "mic_off" : "mic"

    readonly property string icon: {
        if (muted) return "volume_off";
        if (volumePercent === 0) return "volume_mute";
        if (volumePercent <= 25) return "volume_down";
        return "volume_up";
    }

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

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleSourceMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setVolume(value: real): void {
        if (sink?.audio)
            sink.audio.volume = value;
    }

    function setSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    PwObjectTracker {
        objects: root.sinks.concat([root.sink, root.source])
    }
}
