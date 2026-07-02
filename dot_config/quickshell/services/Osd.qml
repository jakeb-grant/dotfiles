pragma Singleton

import Quickshell
import QtQuick
import qs.services as Services

Singleton {
    id: root

    // "volume" | "brightness" | "media" | "mic" — what the overlay renders
    property string mode: ""
    readonly property bool visible: hideTimer.running

    // Volume/brightness values sync asynchronously at shell start (Pipewire
    // binding, backlight FileView load). Those initial changes must not flash
    // the OSD at login, so value-watching starts after a grace period.
    // (A swallow-the-first-change latch would be airtight against slow logins
    // but eats the first real keypress whenever the init value binds before
    // this singleton instantiates — worse trade than a rare cosmetic flash.)
    property bool _ready: false
    Timer {
        interval: 2000
        running: true
        onTriggered: root._ready = true
    }

    Timer {
        id: hideTimer
        interval: 1400
    }

    function show(which: string): void {
        if (!_ready) return;
        // The matching popout already shows richer live feedback — don't
        // double up while it's open.
        if (Services.Popout.isOpen && Services.Popout.currentName === which) return;
        mode = which;
        hideTimer.restart();
    }

    // Media keys are explicit keypresses, never a startup echo, so no _ready
    // guard. Track info lives in the volume popout, hence that suppression.
    function showMedia(): void {
        if (Services.Popout.isOpen && Services.Popout.currentName === "volume") return;
        mode = "media";
        hideTimer.restart();
    }

    // sourceMuted is derived from the default source, so it also flips when
    // the source *device* changes (headset plug/unplug — unplugging a muted
    // headset would flash "Microphone on"). Only a mute change on the same
    // source is a user toggle worth showing. Update-then-compare keeps this
    // correct regardless of sourceChanged/sourceMutedChanged emission order.
    property var _lastSource: null
    Component.onCompleted: _lastSource = Services.Audio.source

    Connections {
        target: Services.Audio
        function onVolumePercentChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
        function onSourceChanged() { root._lastSource = Services.Audio.source; }
        function onSourceMutedChanged() {
            const s = Services.Audio.source;
            const switched = s !== root._lastSource;
            root._lastSource = s;
            if (!switched) root.show("mic");
        }
    }

    Connections {
        target: Services.Brightness
        function onPercentChanged() { root.show("brightness"); }
    }
}
