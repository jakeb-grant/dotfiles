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
    readonly property bool isPaused: active?.playbackState === MprisPlaybackState.Paused

    // ── Metadata ──
    readonly property string trackTitle: active?.trackTitle ?? ""
    readonly property string trackArtist: active?.trackArtist ?? ""
    readonly property string trackAlbum: active?.trackAlbum ?? ""
    readonly property string trackArtUrl: active?.trackArtUrl ?? ""
    readonly property string playerName: active?.identity ?? ""

    // ── Playback ──
    readonly property real length: active?.length ?? 0
    readonly property real position: active?.position ?? 0
    readonly property real volume: active?.volume ?? 0

    // ── Live position (interpolated between MPRIS updates) ──
    property real livePosition: 0

    onPositionChanged: livePosition = position
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
    readonly property bool canPlay: active?.canPlay ?? false
    readonly property bool canPause: active?.canPause ?? false
    readonly property bool canSeek: active?.canSeek ?? false

    // ── Loop / Shuffle ──
    readonly property var loopState: active?.loopState ?? MprisLoopState.None
    readonly property bool shuffle: active?.shuffle ?? false
    readonly property bool loopSupported: active?.loopSupported ?? false
    readonly property bool shuffleSupported: active?.shuffleSupported ?? false

    // ── Raw players passthrough ──
    readonly property var players: Mpris.players

    // ── Controls ──
    function togglePlaying(): void {
        active?.togglePlaying();
    }
    function play(): void {
        active?.play();
    }
    function pause(): void {
        active?.pause();
    }
    function stop(): void {
        active?.stop();
    }
    function next(): void {
        active?.next();
    }
    function previous(): void {
        active?.previous();
    }
    function seek(offset: real): void {
        active?.seek(offset);
    }
    function setVolume(vol: real): void {
        if (active) active.volume = vol;
    }
    function setPosition(pos: real): void {
        if (active) active.position = pos;
    }
    function setLoopState(state): void {
        if (active) active.loopState = state;
    }
    function setShuffle(on: bool): void {
        if (active) active.shuffle = on;
    }
    function raise(): void {
        active?.raise();
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
