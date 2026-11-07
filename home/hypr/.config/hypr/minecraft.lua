-- Minecraft: Solange das Fenster fokussiert ist, ist die F-Tastenreihe umgedreht:
-- ohne Fn kommen F-Tasten im Spiel an, mit Fn gibt es die Laptop-Funktionen.
--
-- Die Fn-Taste selbst sieht das System nicht, die Firmware sendet je nach Fn einen anderen Code.
-- Gemessen am HP Pavilion x360 15-er0 (libinput debug-events):
--   Taste   ohne Fn                          mit Fn
--   F1      SUPER + F1 (nur kurzer Impuls)   F1
--   F2/F3   Helligkeit (Impulse)             F2/F3
--   F4      nichts (Firmware)                F4      -> ohne Fn nicht umbiegbar
--   F5      Stumm (nur kurzer Impuls)        F5
--   F6/F7   Lautstärke (Impulse)             F6/F7
--   F8-F10  Medien (nur kurzer Impuls)       F8-F10
--   F11     SUPER + P (echtes Halten)        F11
--   F12     Insert (echtes Halten)           F12
-- F1, F4, F11 und F12 haben mit Fn keine Laptop-Funktion und bleiben dort einfach F-Tasten.

local CLASS = "com.mojang.minecraft"

-- Tasten mit Firmware-Wiederholung senden beim Halten nur Impulse (erste Pause ca. 340 ms).
-- Die F-Taste bleibt deshalb bis HOLD_MS nach dem letzten Impuls gedrückt, damit z.B. F3 + G geht.
local HOLD_MS = 400
local TAP_MS = 50

-- Laptop-Taste -> F-Taste im Spiel; ms = Impulstaste, sonst echtes Drücken/Loslassen
local TO_GAME = {
    { from = "SUPER + F1",            to = "F1",  ms = TAP_MS },
    { from = "XF86MonBrightnessDown", to = "F2",  ms = HOLD_MS },
    { from = "XF86MonBrightnessUp",   to = "F3",  ms = HOLD_MS },
    { from = "XF86AudioMute",         to = "F5",  ms = TAP_MS },
    { from = "XF86AudioLowerVolume",  to = "F6",  ms = HOLD_MS },
    { from = "XF86AudioRaiseVolume",  to = "F7",  ms = HOLD_MS },
    { from = "XF86AudioPrev",         to = "F8",  ms = TAP_MS },
    { from = "XF86AudioPlay",         to = "F9",  ms = TAP_MS },
    { from = "XF86AudioNext",         to = "F10", ms = TAP_MS },
    { from = "SUPER + P",             to = "F11" },
    { from = "Insert",                to = "F12" },
}

-- F-Taste (also Fn gedrückt) -> Laptop-Funktion
local TO_LAPTOP = {
    { key = "F2",  media = "XF86MonBrightnessDown", repeating = true },
    { key = "F3",  media = "XF86MonBrightnessUp",   repeating = true },
    { key = "F5",  media = "XF86AudioMute" },
    { key = "F6",  media = "XF86AudioLowerVolume",  repeating = true },
    { key = "F7",  media = "XF86AudioRaiseVolume",  repeating = true },
    { key = "F8",  media = "XF86AudioPrev" },
    { key = "F9",  media = "XF86AudioPlay" },
    { key = "F10", media = "XF86AudioNext" },
}

local media = require("keybind").media

local game_window = nil
local pressed = {}
local generation = {}
local timers = {} -- Referenz halten, damit der Garbage Collector den Timer nicht abräumt
local game_binds = {}

local function send(key, state)
    -- pcall: das Fenster kann beim Loslassen schon geschlossen sein
    pcall(hl.dispatch, hl.dsp.send_key_state({ mods = "", key = key, state = state, window = game_window }))
end

local function press(key)
    if not pressed[key] then
        pressed[key] = true
        send(key, "down")
    end
end

local function release(key)
    if pressed[key] then
        pressed[key] = nil
        send(key, "up")
    end
end

local function pulse(key, ms)
    press(key)
    local current = (generation[key] or 0) + 1
    generation[key] = current
    timers[key] = hl.timer(function()
        if generation[key] == current then
            release(key)
        end
    end, { timeout = ms, type = "oneshot" })
end

local function add_game_bind(keys, callback, opts)
    local bind = hl.bind(keys, callback, opts)
    bind:set_enabled(false)
    game_binds[#game_binds + 1] = bind
end

for _, entry in ipairs(TO_GAME) do
    local description = "Minecraft: " .. entry.to
    if entry.ms then
        add_game_bind(entry.from, function() pulse(entry.to, entry.ms) end, { description = description })
    else
        add_game_bind(entry.from, function() press(entry.to) end, { description = description })
        add_game_bind(entry.from, function() release(entry.to) end,
            { release = true, description = description .. " loslassen" })
    end
end

for _, entry in ipairs(TO_LAPTOP) do
    local cmd = media[entry.media].cmd
    add_game_bind(entry.key, hl.dsp.exec_cmd(cmd), {
        repeating = entry.repeating,
        description = "Minecraft: Fn + " .. entry.key .. " Laptop-Funktion",
    })
end

local active = false
-- Wert aus inputs.lua merken (wird dort vor diesem Modul gesetzt)
local disable_while_typing = hl.get_config("input.touchpad.disable_while_typing")

local function sync(win)
    local now_active = win ~= nil and win.class == CLASS
    if now_active then
        game_window = win
    end
    if now_active == active then
        return
    end
    active = now_active

    -- Beim Fokusverlust nichts im Spiel gedrückt lassen
    if not active then
        for key in pairs(pressed) do
            release(key)
        end
    end

    for _, bind in ipairs(game_binds) do
        bind:set_enabled(active)
    end
    for _, entry in pairs(media) do
        entry.bind:set_enabled(not active)
    end

    -- Touchpad beim Tippen nicht sperren, damit man z.B. mit WASD laufen und gleichzeitig zielen kann
    hl.config({ input = { touchpad = { disable_while_typing = (not active) and disable_while_typing } } })
end

hl.on("window.active", sync)
-- Die Klasse kann sich erst nach dem Öffnen des Fensters setzen
hl.on("window.class", function() sync(hl.get_active_window()) end)
sync(hl.get_active_window())


-- außerdem auch noch automatisch Minecraft auf Fullscreen setzen
hl.window_rule({ match = { class = "^com\\.mojang\\.minecraft$" }, fullscreen = true })

return true
