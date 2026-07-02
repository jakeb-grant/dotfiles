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
        name: "media-playpause"
        description: "Play/pause the active media player"
        onPressed: {
            Services.Players.togglePlaying();
            Services.Osd.showMedia();
        }
    }

    GlobalShortcut {
        name: "media-next"
        description: "Skip to next track"
        onPressed: {
            Services.Players.next();
            Services.Osd.showMedia();
        }
    }

    GlobalShortcut {
        name: "media-prev"
        description: "Skip to previous track"
        onPressed: {
            Services.Players.previous();
            Services.Osd.showMedia();
        }
    }

    GlobalShortcut {
        name: "notif-dismiss"
        description: "Dismiss latest notification"
        onPressed: Services.Notifications.dismissLatest()
    }

    GlobalShortcut {
        name: "notif-dismiss-all"
        description: "Dismiss all notifications"
        onPressed: Services.Notifications.dismissAll()
    }

    Drawers {}
}
