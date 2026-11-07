local env = {
    "HYPRCURSOR_THEME,Bibata-Modern-Classic",
    "HYPRCURSOR_SIZE,18",
    "XCURSOR_THEME,Bibata-Modern-Classic",
    "XCURSOR_SIZE,18",
    "QT_CURSOR_THEME,Bibata-Modern-Classic",
    "QT_CURSOR_SIZE,18",
}

for _, item in ipairs(env) do
    local key, value = item:match("^([^,]+),(.+)$")
    if key and value then
        hl.env(key, value)
    end
end

hl.config({
    general = {
        gaps_in = 1.5,
        gaps_out = 3,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,
        shadow = {
            enabled = false,
        },
        active_opacity = 1.0,
        inactive_opacity = 0.98,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = true,
            size = 1,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            special = true,
        },
    },
})
