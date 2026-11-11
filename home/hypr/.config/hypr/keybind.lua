local scrPath = (os.getenv("HOME") or "") .. "/.config/hypr/Scripts"
local mainMod = "SUPER"
local TERMINAL = "kitty"
local EXPLORER = "thunar"
local BROWSER = "helium"
local SATTY = scrPath .. "/satty.sh"

local KEY = {
	TERMINAL = ("%s + RETURN"):format(mainMod),
	EXPLORER = ("%s + E"):format(mainMod),
	BROWSER = ("%s + B"):format(mainMod),
	LAUNCHER = ("%s + SPACE"):format(mainMod),
	SETTINGS = ("%s + COMMA"):format(mainMod),

	CLOSE = ("%s + Q"):format(mainMod),
	FLOAT = ("%s + SHIFT + T"):format(mainMod),

	FOCUS_LEFT = ("%s + H"):format(mainMod),
	FOCUS_RIGHT = ("%s + L"):format(mainMod),
	FOCUS_UP = ("%s + K"):format(mainMod),
	FOCUS_DOWN = ("%s + J"):format(mainMod),

	RESIZE_RIGHT = ("%s + right"):format(mainMod),
	RESIZE_LEFT = ("%s + left"):format(mainMod),
	RESIZE_UP = ("%s + up"):format(mainMod),
	RESIZE_DOWN = ("%s + down"):format(mainMod),

	MOVE_SWAP_LEFT = ("%s + SHIFT + H"):format(mainMod),
	MOVE_SWAP_RIGHT = ("%s + SHIFT + L"):format(mainMod),
	MOVE_SWAP_UP = ("%s + SHIFT + K"):format(mainMod),
	MOVE_SWAP_DOWN = ("%s + SHIFT + J"):format(mainMod),

	SCROLL_WORKSPACE_NEXT = ("%s + mouse_down"):format(mainMod),
	SCROLL_WORKSPACE_PREV = ("%s + mouse_up"):format(mainMod),

	MOUSE_DRAG = ("%s + mouse:272"):format(mainMod),
	MOUSE_RESIZE = ("%s + mouse:273"):format(mainMod),
}

-- 1. Applications
hl.bind(KEY.TERMINAL, hl.dsp.exec_cmd(TERMINAL), { description = "Terminal" })
hl.bind(KEY.EXPLORER, hl.dsp.exec_cmd(EXPLORER), { description = "File manager" })
hl.bind(KEY.BROWSER, hl.dsp.exec_cmd(BROWSER), { description = "Browser" })
hl.bind(("%s + N"):format(mainMod), hl.dsp.exec_cmd("zennotes"), { description = "Notizapp ZenNotes" })
hl.bind(("%s + Z"):format(mainMod), hl.dsp.exec_cmd("zotero"), { description = "Zotero" })

-- 2. Noctalia
hl.bind(KEY.LAUNCHER, hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "Toggle launcher" })
hl.bind(KEY.SETTINGS, hl.dsp.exec_cmd("noctalia msg settings-toggle"), { description = "Toggle settings" })
-- Power-/Session-Menü (Ausschalten, Neustart, Sperren, Abmelden …)
hl.bind(("%s + Escape"):format(mainMod), hl.dsp.exec_cmd("noctalia msg panel-toggle session"),
	{ description = "Toggle power menu" })
-- Power-off
hl.bind(("%s + CTRL + ESCAPE"):format(mainMod), hl.dsp.exec_cmd("systemctl poweroff"), { description = "Power off" })
-- Bluetooth/WLAN: Control-Center direkt im passenden Tab öffnen
hl.bind(("%s + CTRL + B"):format(mainMod), hl.dsp.exec_cmd("noctalia msg panel-toggle control-center bluetooth"),
	{ description = "Toggle Bluetooth menu" })
hl.bind(("%s + CTRL + W"):format(mainMod), hl.dsp.exec_cmd("noctalia msg panel-toggle control-center network"),
	{ description = "Toggle Wi-Fi menu" })
-- Caffeine = Idle-Inhibitor: verhindert automatisches Sperren/Bildschirm-aus
hl.bind(("%s + CTRL + I"):format(mainMod), hl.dsp.exec_cmd("noctalia msg caffeine-toggle"),
	{ description = "Toggle caffeine (no idle lock)" })
-- Paket-Menü: Noctalia-Plugin (config/noctalia/plugins/pkg-menu), startet pkg-install/-remove/-copr in kitty
hl.bind(("%s + ALT + SPACE"):format(mainMod), hl.dsp.exec_cmd('noctalia msg panel-toggle launcher "/pkg "'),
	{ description = "Package menu (install/remove/COPR)" })
-- Theme-Untermenü desselben Plugins direkt öffnen
hl.bind(("%s + CTRL + SHIFT + SPACE"):format(mainMod),
	hl.dsp.exec_cmd('noctalia msg panel-toggle launcher "/pkg theme "'),
	{ description = "Theme menu" })
-- Wallpaper select
hl.bind(("%s + CTRL + SPACE"):format(mainMod), hl.dsp.exec_cmd('noctalia msg panel-toggle wallpaper'),
	{ description = 'Wallpaper menu' })
--- Clipboard Menu
hl.bind(("%s + CTRL + V"):format(mainMod), hl.dsp.exec_cmd('noctalia msg panel-toggle clipboard'),
	{ description = "Toggle Clipboard menu" })

-- 3. Window Management
hl.bind(KEY.CLOSE, hl.dsp.window.close(), { description = "Close window" })
hl.bind(KEY.FLOAT, hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Force full screen" })

-- 4. Window Navigation & Layout
hl.bind(KEY.FOCUS_LEFT, hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind(KEY.FOCUS_RIGHT, hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind(KEY.FOCUS_UP, hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind(KEY.FOCUS_DOWN, hl.dsp.focus({ direction = "down" }), { description = "Focus down" })

hl.bind("ALT + tab", hl.dsp.window.cycle_next(), { description = "Cycle windows" })

hl.bind(KEY.RESIZE_RIGHT, hl.dsp.window.resize({
	x = 30,
	y = 0,
	relative = true
}), { description = "Resize window right" })

hl.bind(KEY.RESIZE_LEFT, hl.dsp.window.resize({
	x = -30,
	y = 0,
	relative = true
}), { description = "Resize window left" })

hl.bind(KEY.RESIZE_UP, hl.dsp.window.resize({
	x = 0,
	y = -30,
	relative = true
}), { description = "Resize window up" })

hl.bind(KEY.RESIZE_DOWN, hl.dsp.window.resize({
	x = 0,
	y = 30,
	relative = true
}), { description = "Resize window down" })

hl.bind(
	KEY.MOVE_SWAP_LEFT,
	hl.dsp.window.move({ direction = "left" }),
	{ description = "Move or swap window left" }
)

hl.bind(
	KEY.MOVE_SWAP_RIGHT,
	hl.dsp.window.move({ direction = "right" }),
	{ description = "Move or swap window right" }
)

hl.bind(
	KEY.MOVE_SWAP_UP,
	hl.dsp.window.move({ direction = "up" }),
	{ description = "Move or swap window up" }
)

hl.bind(
	KEY.MOVE_SWAP_DOWN,
	hl.dsp.window.move({ direction = "down" }),
	{ description = "Move or swap window down" }
)

-- 5. Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m region"),
	{ description = "Screenshot region" })
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd(SATTY), { description = "Screenshot Annotate" })

-- 6. Workspace Switching
for i = 1, 9 do
	local focusKey = ("%s + %d"):format(mainMod, i)
	local moveKey = ("%s + SHIFT + %d"):format(mainMod, i)
	hl.bind(focusKey, hl.dsp.focus({ workspace = i }), { description = "Workspace " .. i })
	hl.bind(moveKey, hl.dsp.window.move({ workspace = i }), { description = "Move to workspace " .. i })
end
hl.bind(("%s + 0"):format(mainMod), hl.dsp.focus({ workspace = 10 }), { description = "Workspace 10" })
hl.bind(("%s + SHIFT + 0"):format(mainMod), hl.dsp.window.move({ workspace = 10 }),
	{ description = "Move to workspace 10" })
hl.bind("SUPER + X", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle scratchpad" })
hl.bind("SUPER + SHIFT + X",
	hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), { description = "Move window to scratchpad" })
hl.bind("SUPER + O", hl.dsp.focus({ last = true }), { description = "Focus previous window" })
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 9. Mouse Workspace Navigation
hl.bind(KEY.SCROLL_WORKSPACE_NEXT, hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll to next workspace" })
hl.bind(KEY.SCROLL_WORKSPACE_PREV, hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll to previous workspace" })

-- 10. Mouse Window Management
hl.bind(KEY.MOUSE_DRAG, hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(KEY.MOUSE_RESIZE, hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- 11. Media & Helligkeit (Handles + Befehle für minecraft.lua, das diese Tasten im Spiel umbiegt)
local media = {}
local function media_bind(key, cmd, opts)
	opts.locked = true
	media[key] = { bind = hl.bind(key, hl.dsp.exec_cmd(cmd), opts), cmd = cmd }
end

media_bind("XF86AudioPlay", "noctalia msg media toggle", { description = "Play or pause" })
media_bind("XF86AudioNext", "noctalia msg media next", { description = "Next track" })
media_bind("XF86AudioPrev", "noctalia msg media previous", { description = "Previous track" })
media_bind("XF86AudioRaiseVolume", "noctalia msg volume-up 5%", { description = "Volume up" })
media_bind("XF86AudioLowerVolume", "noctalia msg volume-down 5%", { description = "Volume down" })
media_bind("XF86AudioMute", "noctalia msg volume-mute", { description = "Volume mute" })
media_bind("XF86MonBrightnessUp", "noctalia msg brightness-up", { repeating = true, description = "Brightness up" })
media_bind("XF86MonBrightnessDown", "noctalia msg brightness-down", { repeating = true, description = "Brightness down" })

-- 12. Mikrofon (nicht in der Fn-Reihe, bleibt auch in Minecraft unverändert)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"),
	{ locked = true, description = "Microphone mute" })

-- Nachtlicht
hl.bind("SUPER + CTRL + N", hl.dsp.exec_cmd("noctalia msg nightlight-force-toggle"),
	{ description = "Nightlight toggeln" })



-- Zotero-Quelle als Fußnote in die offene ZenNotes-Notiz einfügen
hl.bind(("%s + CTRL + Z"):format(mainMod), hl.dsp.exec_cmd(scrPath .. "/zotero-footnote.py"),
	{ description = "Zotero footnote" })

return { media = media }
