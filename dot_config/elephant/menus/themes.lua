-- Theme Switcher Menu for Walker/Elephant
-- Dynamically lists themes with wallpaper previews

Name = "themes"
NamePretty = "Theme Switcher"
Icon = "preferences-desktop-theme"

local THEME_DIR = os.getenv("HOME") .. "/.config/themes"
local WALLPAPER_DIR = os.getenv("HOME") .. "/.config/wallpapers"

-- Apps that should be closed before switching themes
local BLOCKING_APPS = { "zed", "nautilus", "gnome-text-editor", "evince", "eog", "loupe" }

-- Simple function to extract _wallpaper value from JSON
local function get_wallpaper(content)
    local wallpaper = content:match('"_wallpaper"%s*:%s*"([^"]+)"')
    return wallpaper or ""
end

function GetEntries()
    local entries = {}

    -- Check for running blocking apps
    local running_apps = {}
    for _, app in ipairs(BLOCKING_APPS) do
        local handle = io.popen("pgrep -x " .. app .. " 2>/dev/null")
        if handle then
            local result = handle:read("*a")
            handle:close()
            if result and result ~= "" then
                table.insert(running_apps, app)
            end
        end
    end

    -- If blocking apps are running, show warning entry
    if #running_apps > 0 then
        local apps_list = table.concat(running_apps, ", ")
        table.insert(entries, {
            Text = "Close these apps first: " .. apps_list,
            Icon = "dialog-warning",
            Keywords = { "warning", "close" },
        })
        return entries
    end

    -- Get active theme
    local active_handle = io.popen('readlink "' .. THEME_DIR .. '/active.json" 2>/dev/null')
    local active_theme = ""
    if active_handle then
        active_theme = active_handle:read("*a"):gsub("%s+", ""):gsub("%.json$", "")
        active_handle:close()
    end

    -- Find all theme JSON files
    local handle = io.popen('find "' .. THEME_DIR .. '" -maxdepth 1 -name "*.json" -not -name "active.json" 2>/dev/null')
    if not handle then
        return entries
    end

    for file in handle:lines() do
        local theme_name = file:match("([^/]+)%.json$")

        if theme_name then
            -- Read theme file to get wallpaper
            local theme_file = io.open(file, "r")
            local wallpaper = ""
            if theme_file then
                local content = theme_file:read("*a")
                theme_file:close()
                wallpaper = get_wallpaper(content)
            end

            local wallpaper_path = WALLPAPER_DIR .. "/" .. wallpaper
            local is_active = (theme_name == active_theme)
            local display_name = theme_name:gsub("-", " "):gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end)

            if is_active then
                display_name = display_name .. " (active)"
            end

            local entry = {
                Text = display_name,
                Icon = "preferences-desktop-theme",
                Keywords = { theme_name, "theme", "switch", "wallpaper" },
                Actions = {
                    ["open"] = "theme-switch " .. theme_name,
                },
            }

            -- Add wallpaper preview if it exists
            if wallpaper ~= "" then
                local f = io.open(wallpaper_path, "r")
                if f then
                    f:close()
                    entry.Preview = wallpaper_path
                    entry.PreviewType = "file"
                end
            end

            -- Mark active theme
            if is_active then
                entry.State = { "current" }
            end

            table.insert(entries, entry)
        end
    end
    handle:close()

    return entries
end
