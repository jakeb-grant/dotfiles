pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property list<Notification> popups: []
    readonly property int count: popups.length
    readonly property int defaultTimeout: 5000

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
            root._timestamps[notif.id] = Date.now();
            root._new[notif.id] = true;
            root._newRev++;
            root.popups = [notif, ...root.popups.slice(0, 4)];
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

    // Called by card after exit animation completes
    function finishRemoval(notif: Notification): void {
        if (!_dismissing[notif.id]) return;
        const action = _dismissing[notif.id];
        delete _dismissing[notif.id];
        delete _timestamps[notif.id];
        delete _new[notif.id];
        popups = popups.filter(n => n !== notif);
        if (action === "dismiss")
            notif.dismiss();
    }

    function dismissLatest(): void {
        if (popups.length > 0)
            animatedDismiss(popups[0]);
    }

    function dismissAll(): void {
        const all = popups.slice();
        popups = [];
        _timestamps = {};
        _dismissing = {};
        _new = {};
        _dismissRev++;
        _newRev++;
        for (const n of all)
            n.dismiss();
    }

    function remainingTimeout(notif: Notification): int {
        const timeout = notif.expireTimeout > 0 ? notif.expireTimeout : defaultTimeout;
        const created = _timestamps[notif.id] ?? Date.now();
        return Math.max(100, timeout - (Date.now() - created));
    }
}
