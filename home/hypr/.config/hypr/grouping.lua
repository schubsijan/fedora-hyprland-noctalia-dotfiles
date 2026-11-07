local mainMod = "SUPER"

-- Fokussiertes Fenster mit dem Nachbarn in Richtung gruppieren.
-- Ist der Nachbar bereits Teil einer Gruppe, wird das Fenster dieser Gruppe hinzugefügt,
-- sonst wird aus beiden Fenstern eine neue Gruppe erstellt.
local GROUP_DIRECTIONS = {
    W = "up",
    S = "down",
    A = "left",
    D = "right",
}

for key, direction in pairs(GROUP_DIRECTIONS) do
    hl.bind(("%s + %s"):format(mainMod, key),
        hl.dsp.window.move({ into_or_create_group = direction }),
        { description = "Group with window " .. direction })
end

-- Innerhalb der Gruppe navigieren
hl.bind(("%s + N"):format(mainMod), hl.dsp.group.next(), { description = "Next window in group" })
hl.bind(("%s + P"):format(mainMod), hl.dsp.group.prev(), { description = "Previous window in group" })

-- Gruppe auflösen (nur wenn das fokussierte Fenster in einer Gruppe ist,
-- sonst würde toggle eine neue Gruppe erstellen)
hl.bind(("%s + udiaeresis"):format(mainMod), function()
    local win = hl.get_active_window()
    if win and win.group then
        hl.dispatch(hl.dsp.group.toggle())
    end
end, { description = "Dissolve group" })

return true
