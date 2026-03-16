//@ pragma Env QSG_RENDER_LOOP=threaded

import qs.modules.drawers
import qs.services as Services
import qs.utils
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    GlobalShortcut {
        name: "launcher"
        description: "Toggle app launcher"
        onPressed: Services.Launcher.toggle()
    }

    GlobalShortcut {
        name: "notif-dismiss"
        description: "Dismiss latest notification"
        onPressed: {
            if (Services.Notifications.popups.length > 0)
                Services.Notifications.animatedDismiss(Services.Notifications.popups[0]);
        }
    }

    GlobalShortcut {
        name: "notif-dismiss-all"
        description: "Dismiss all notifications"
        onPressed: Services.Notifications.dismissAll()
    }

    GlobalShortcut {
        name: "notif-panel"
        description: "Toggle notification panel"
        onPressed: Services.Notifications.toggleExpanded()
    }

    Drawers {}
}
