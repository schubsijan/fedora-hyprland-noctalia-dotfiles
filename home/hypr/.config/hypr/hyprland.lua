local config_dir = (os.getenv("HOME") or "") .. "/.config/hypr"
package.path = table.concat({
    config_dir .. "/?.lua",
    config_dir .. "/?/init.lua",
    package.path,
}, ";")

-- Clear cached modules so they re-execute on reload (ensures binds/rules re-register)
for _, mod in ipairs({ "monitors", "inputs", "keybind", "scrolling", "grouping", "minecraft", "windowrules", "animations", "themes.theme" }) do
    package.loaded[mod] = nil
end

require("monitors")
require("startup")
require("inputs")
require("keybind")
require("scrolling")
require("grouping")
require("minecraft")
require("windowrules")
require("animations")
require("themes.theme")

hl.config({
    dwindle = {
        preserve_split = false,
        force_split = 2,
        smart_split = false,
        smart_resizing = false,
        use_active_for_splits = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        anr_missed_pings = 5,
        allow_session_lock_restore = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    general = {
        snap = {
            enabled = false,
        },
    },
})

-- For Noctalia Color templates
require("noctalia").apply_theme()

hl.device({
    name = "elan2514:00-04f3:2ce2",
    enabled = false
})

hl.device({
    name = "elan2514:00-04f3:2ce2-stylus",
    enabled = false
})
