pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property list<Notification> popups: []
    readonly property int count: popups.length
    readonly property int defaultTimeout: 5000
    readonly property int historyLimit: 50

    property alias dnd: persist.dnd
    // Plain-data snapshots, newest first. Notification objects are released
    // on dismissal, so history keeps copies, not references. Derived from the
    // JSON below — re-parses on every write and on reload restore.
    readonly property var history: JSON.parse(persist.historyJson || "[]")

    // theme-switch reloads the shell, so DND and history must survive live
    // reloads — losing them there would be silent. (Full quickshell restarts
    // still clear both; accepted.) History is stored as a JSON string:
    // PersistentProperties can't carry JS arrays across reload engines —
    // a `property var` comes back undefined ("JSValue can't be reassigned
    // to another engine").
    PersistentProperties {
        id: persist
        reloadableId: "notificationsService"

        property bool dnd: false
        property string historyJson: "[]"
    }

    function toggleDnd(): void {
        persist.dnd = !persist.dnd;
    }

    // Snapshot at arrival — one code path covers every exit (dismiss, expire,
    // cap-drop, DND-suppress). Text is stored raw (launcher rows render
    // PlainText; stripping markup naively corrupts text like "5 < 10") but
    // capped at 4 KiB per field: one pathological notification would
    // otherwise bloat historyJson — re-stringified on every arrival — and
    // push Enter-to-copy past the kernel's per-arg limit.
    function _addToHistory(notif: Notification): void {
        const entry = {
            appName: notif.appName ?? "",
            appIcon: notif.appIcon ?? "",
            summary: (notif.summary ?? "").substring(0, 4096),
            body: (notif.body ?? "").substring(0, 4096),
            critical: notif.urgency === NotificationUrgency.Critical,
            time: Date.now(),
        };
        persist.historyJson = JSON.stringify([entry, ...history.slice(0, historyLimit - 1)]);
    }

    // Track creation times so Repeater recreation doesn't reset timers
    property var _timestamps: ({})

    // Track notifications in exit animation so recreated delegates stay hidden
    property var _dismissing: ({})
    property int _dismissRev: 0

    // One-shot set: notif id present means "no card has been instantiated yet" →
    // first card should play the entrance animation. Cleared on first
    // Component.onCompleted so Repeater recreations don't re-animate.
    property var _new: ({})
    property int _newRev: 0

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            if (notif.lastGeneration) return;
            root._addToHistory(notif);
            // DND: no card for non-critical notifications (critical bypasses).
            // expire() rather than dismiss() — it releases blocking senders
            // (notify-send --wait/-A) without claiming the user acted on it.
            if (persist.dnd && notif.urgency !== NotificationUrgency.Critical) {
                notif.expire();
                return;
            }
            // tracked=true keeps the Notification object alive (and its
            // text/body queryable) for as long as we hold a reference. Without
            // it the server invalidates older notifications when new ones
            // arrive — text goes empty and onClosed fires prematurely,
            // bypassing our expireTimer. We undo this in finishRemoval by
            // calling notif.dismiss().
            notif.tracked = true;
            root._timestamps[notif.id] = Date.now();
            root._new[notif.id] = true;
            root._newRev++;
            // Cap at 5 — anything displaced past the window is no longer ours
            // to track. Dismiss it (releases tracked=true) and clean local state.
            const kept = root.popups.slice(0, 4);
            for (const dropped of root.popups.slice(4)) {
                delete root._dismissing[dropped.id];
                delete root._timestamps[dropped.id];
                delete root._new[dropped.id];
                dropped.dismiss();
            }
            root.popups = [notif, ...kept];
        }
    }

    function isDismissing(notif: Notification): bool {
        void _dismissRev;
        return !!_dismissing[notif.id];
    }

    function isNew(notif: Notification): bool {
        void _newRev;
        return !!_new[notif.id];
    }

    // Called once per notification when its card first mounts.
    function markSeen(notif: Notification): void {
        if (_new[notif.id]) {
            delete _new[notif.id];
            _newRev++;
        }
    }

    // Start exit animation — card will call finishRemoval after animating
    function animatedRemove(notif: Notification): void {
        if (_dismissing[notif.id]) return;
        _dismissing[notif.id] = "remove";
        _dismissRev++;
    }

    function animatedDismiss(notif: Notification): void {
        if (_dismissing[notif.id]) return;
        _dismissing[notif.id] = "dismiss";
        _dismissRev++;
    }

    // Called by card after exit animation completes. Always dismiss — history
    // was snapshotted at arrival, so nothing needs the live object; we release
    // the tracked=true reference here.
    function finishRemoval(notif: Notification): void {
        if (!_dismissing[notif.id]) return;
        delete _dismissing[notif.id];
        delete _timestamps[notif.id];
        delete _new[notif.id];
        popups = popups.filter(n => n !== notif);
        notif.dismiss();
    }

    function dismissLatest(): void {
        if (popups.length > 0)
            animatedDismiss(popups[0]);
    }

    function dismissAll(): void {
        // Mark every popup as dismissing so cards animate out together —
        // clearing _dismissing here would snap mid-fade cards back to opacity 1.
        for (const n of popups)
            _dismissing[n.id] = "dismiss";
        _dismissRev++;
    }

    function remainingTimeout(notif: Notification): int {
        const timeout = notif.expireTimeout > 0 ? notif.expireTimeout : defaultTimeout;
        const created = _timestamps[notif.id] ?? Date.now();
        return Math.max(100, timeout - (Date.now() - created));
    }
}
