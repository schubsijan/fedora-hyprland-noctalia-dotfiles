local mainMod = "SUPER"

local SCROLLING_LAYOUT = "scrolling"
local TILING_LAYOUT = "dwindle"

local LAYOUT_LABEL = {
    [SCROLLING_LAYOUT] = "Scrolling-Layout",
    [TILING_LAYOUT] = "Tiling-Layout (dwindle)",
}

hl.config({
    scrolling = {
        column_width = 0.49,
        focus_fit_method = 1,
        explicit_column_widths = "0.33, 0.49, 0.98"
    },
})

local function get_workspace()
    local ws = hl.get_active_workspace()
    if not ws or ws.special then
        return nil
    end
    return ws
end

local function set_layout(layout)
    local ws = get_workspace()
    if not ws then
        return
    end

    -- Workspace-Regel setzen: das Layout wird dadurch sofort auf den Workspace angewendet
    hl.workspace_rule({ workspace = ws.config_name, layout = layout })
    hl.dsp.exec_cmd(("noctalia msg notification-show 'Layout: %s'"):format(LAYOUT_LABEL[layout] or layout))
end

-- zwischen den verschiednenen col-Breiten umschalten
hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"),
    { description = "Toggle column resize" })
-- Zwischen Scrolling und Tiling umschalten (aktiver Workspace)
hl.bind(("%s + U"):format(mainMod), function()
    local ws = get_workspace()
    if not ws then
        return
    end

    set_layout(ws.tiled_layout == SCROLLING_LAYOUT and TILING_LAYOUT or SCROLLING_LAYOUT)
end, { description = "Toggle scrolling layout" })

return true
