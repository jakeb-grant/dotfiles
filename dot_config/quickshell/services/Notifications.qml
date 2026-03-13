pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property list<Notification> popups: []
    readonly property int count: popups.length
    readonly property int defaultTimeout: 5000

    // Notification center state
    readonly property var history: server.trackedNotifications
    property int historyCount: 0
    property bool expanded: false

    // Track creation times so Repeater recreation doesn't reset timers
    property var _timestamps: ({})

    // Track notifications in exit animation so recreated delegates stay hidden
    property var _dismissing: ({})
    property int _dismissRev: 0

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            if (notif.lastGeneration) return;
            notif.tracked = true;
            root.historyCount++;
            root._timestamps[notif.id] = Date.now();
            root.popups = [notif, ...root.popups.slice(0, 4)];
        }
    }

    function isDismissing(notif: Notification): bool {
        void _dismissRev;
        return !!_dismissing[notif.id];
    }

    // Start exit animation — card will call finishRemove/finishDismiss after animating
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
        popups = popups.filter(n => n !== notif);
        // "dismiss" = user closed → remove from history too
        // "remove" = auto-timeout → keep tracked for notification center
        if (action === "dismiss") {
            delete _timestamps[notif.id];
            historyCount = Math.max(0, historyCount - 1);
            notif.dismiss();
        }
    }

    function removePopup(notif: Notification): void {
        delete _dismissing[notif.id];
        delete _timestamps[notif.id];
        popups = popups.filter(n => n !== notif);
    }

    function dismiss(notif: Notification): void {
        removePopup(notif);
        historyCount = Math.max(0, historyCount - 1);
        notif.dismiss();
    }

    function dismissAll(): void {
        const all = popups.slice();
        popups = [];
        _timestamps = {};
        _dismissing = {};
        _dismissRev++;
        historyCount = 0;
        for (const n of all)
            n.dismiss();
    }

    function isNew(notif: Notification): bool {
        const t = _timestamps[notif.id];
        return t !== undefined && (Date.now() - t) < 150;
    }

    function remainingTimeout(notif: Notification): int {
        const timeout = notif.expireTimeout > 0 ? notif.expireTimeout : defaultTimeout;
        const created = _timestamps[notif.id] ?? Date.now();
        return Math.max(100, timeout - (Date.now() - created));
    }

    function toggleExpanded(): void {
        expanded = !expanded;
    }

    function dismissFromHistory(notif: Notification): void {
        removePopup(notif);
        historyCount = Math.max(0, historyCount - 1);
        notif.dismiss();
    }

    function clearHistory(): void {
        const all = history.values.slice();
        popups = [];
        _timestamps = {};
        _dismissing = {};
        _dismissRev++;
        historyCount = 0;
        expanded = false;
        for (const n of all)
            n.dismiss();
    }
}
