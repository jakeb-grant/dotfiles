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

    Drawers {}
}
