pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    // ── Active player selection ──
    readonly property MprisPlayer active: _pickActive()
    readonly property bool hasPlayer: active !== null
    readonly property bool isPlaying: active?.playbackState === MprisPlaybackState.Playing

    // ── Metadata ──
    readonly property string trackTitle: active?.trackTitle ?? ""
    readonly property string trackArtist: active?.trackArtist ?? ""
    readonly property string trackArtUrl: active?.trackArtUrl ?? ""

    // ── Playback ──
    readonly property real length: active?.length ?? 0
    readonly property real position: active?.position ?? 0

    // ── Live position (interpolated between MPRIS updates) ──
    property real livePosition: 0

    onPositionChanged: {
        livePosition = position;
        _lastTimestamp = Date.now();
    }
    onIsPlayingChanged: {
        livePosition = position;
        _lastTimestamp = Date.now();
    }
    onActiveChanged: {
        livePosition = position;
        _lastTimestamp = Date.now();
    }

    property real _lastTimestamp: 0

    Timer {
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: {
            const now = Date.now();
            const dt = (now - root._lastTimestamp) / 1000;
            root._lastTimestamp = now;
            root.livePosition = Math.min(root.livePosition + dt, root.length);
        }
    }

    // ── Capabilities ──
    readonly property bool canGoNext: active?.canGoNext ?? false
    readonly property bool canGoPrevious: active?.canGoPrevious ?? false
    readonly property bool canSeek: active?.canSeek ?? false

    // ── Controls ──
    function togglePlaying(): void {
        active?.togglePlaying();
    }
    function next(): void {
        active?.next();
    }
    function previous(): void {
        active?.previous();
    }
    function setPosition(pos: real): void {
        if (active) active.position = pos;
    }

    // ── Internal: pick best player ──
    function _pickActive(): MprisPlayer {
        const ps = Mpris.players.values;
        let paused = null;
        let stopped = null;
        for (let i = 0; i < ps.length; i++) {
            const p = ps[i];
            if (p.playbackState === MprisPlaybackState.Playing) return p;
            if (!paused && p.playbackState === MprisPlaybackState.Paused) paused = p;
            if (!stopped && p.playbackState === MprisPlaybackState.Stopped) stopped = p;
        }
        return paused ?? stopped ?? null;
    }
}
