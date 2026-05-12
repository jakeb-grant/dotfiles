//@ pragma Env QSG_RENDER_LOOP=threaded

import qs.modules.drawers
import qs.modules.lockscreen
import qs.services as Services
import qs.utils as Utils
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    GlobalShortcut {
        name: "lock"
        description: "Lock the session"
        onPressed: Services.LockScreen.lock()
    }

    WlSessionLock {
        id: sessionLock
        locked: Services.LockScreen.locked

        WlSessionLockSurface {
            color: "black"

            LockSurface {
                anchors.fill: parent
            }
        }
    }

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

    Drawers {}
}
