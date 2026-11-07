--!nonstrict
-- Launcher-Provider "/pkg": Auswahlmenü für die Paket-Befehle und den Theme-Wechsel.
-- Enter auf einem Paket-Eintrag öffnet kitty mit dem jeweiligen Befehl (fzf-Suche).
-- PKG_WAIT=1 sorgt dafür, dass das Fenster am Ende auf Enter wartet.
-- "Theme wechseln" bleibt im Launcher und zeigt die Themes ("/pkg theme <filter>").

local BIN = (noctalia.getenv("HOME") or "") .. "/.local/bin/"
local LID_DROPIN = "/etc/systemd/logind.conf.d/50-lid-awake.conf"

local ENTRIES = {
  {
    id = "pkg-update",
    title = "System aktualisieren",
    subtitle = "dnf (inkl. COPR), Flatpak, Firmware prüfen",
    glyph = "refresh",
  },
  {
    id = "pkg-install",
    title = "Paket installieren",
    subtitle = "Fedora-Repos durchsuchen und installieren",
    glyph = "download",
  },
  {
    id = "pkg-remove",
    title = "Paket entfernen",
    subtitle = "Selbst installierte Pakete und Flatpaks durchsuchen und entfernen",
    glyph = "trash",
  },
  {
    id = "pkg-copr",
    title = "COPR-Paket installieren",
    subtitle = "COPR-Projekt suchen, aktivieren und Pakete installieren",
    glyph = "cloud-download",
  },
  {
    id = "lid-awake",
    title = "Zuklappen weiterlaufen", -- Titel, Untertitel und Icon setzt onQuery je nach Zustand
    subtitle = "",
    glyph = "device-laptop",
  },
  {
    id = "theme",
    title = "Theme wechseln",
    subtitle = "Farbschema aus allen verfügbaren Themes auswählen",
    glyph = "palette",
    query = "theme ",
  },
}

-- Noctalia bietet Plugins keine Abfrage dieser beiden Listen an (Stand 5.4.1),
-- nach größeren Updates also mit dem Theme-Menü im Wallpaper-Panel abgleichen.
local BUILTIN_THEMES = {
  "Ayu", "Catppuccin", "Dracula", "Eldritch", "Gruvbox",
  "Kanagawa", "Noctalia", "Nord", "Rosé Pine", "Tokyo-Night",
}
local WALLPAPER_SCHEMES = {
  "m3-content", "m3-tonal-spot", "m3-fruit-salad", "m3-rainbow", "m3-monochrome",
  "vibrant", "faithful", "soft", "dysfunctional", "muted",
}
local COMMUNITY_CATALOG = "~/.local/state/noctalia/community-palettes/.catalog/palettes.json"
local CUSTOM_DIR = "~/.config/noctalia/palettes"

local SOURCE_LABELS = {
  builtin = "Eingebaut",
  community = "Community",
  custom = "Eigenes Theme",
  wallpaper = "Aus Hintergrundbild",
}

local themes = {}
local currentTheme = ""

local function loadThemes()
  themes = {}
  local function add(source, name)
    table.insert(themes, { source = source, name = name })
  end

  for _, name in BUILTIN_THEMES do
    add("builtin", name)
  end
  -- Der Katalog enthält auch noch nicht geladene Themes; Noctalia lädt sie beim Setzen nach.
  local raw = noctalia.readFile(COMMUNITY_CATALOG)
  local catalog = raw and noctalia.json.decode(raw)
  for _, palette in catalog or {} do
    add("community", palette.name)
  end
  for _, file in noctalia.listDir(CUSTOM_DIR) or {} do
    local name = file:match("^(.+)%.json$")
    if name then
      add("custom", name)
    end
  end
  for _, name in WALLPAPER_SCHEMES do
    add("wallpaper", name)
  end
end

local function publishThemes(query, filter)
  local rows = {}
  for _, theme in themes do
    local label = SOURCE_LABELS[theme.source]
    if filter == "" or theme.name:lower():find(filter, 1, true) or label:lower():find(filter, 1, true) then
      local active = currentTheme == theme.source .. " " .. theme.name
      table.insert(rows, {
        id = theme.source .. ":" .. theme.name,
        title = theme.name,
        subtitle = active and (label .. " · aktiv") or label,
        glyph = active and "check" or "palette",
        score = active and 1 or 0, -- aktives Theme steht oben
      })
    end
  end
  launcher.setResults(query, rows)
end

function onQuery(query)
  local text = noctalia.string.trim(query):lower()

  if text == "theme" or text:sub(1, 6) == "theme " then
    local filter = noctalia.string.trim(text:sub(7))
    -- Beim Betreten neu einlesen, beim Tippen im Filter nicht bei jedem Zeichen.
    if filter == "" or #themes == 0 then
      loadThemes()
      noctalia.runAsync({ "noctalia", "msg", "color-scheme-get" }, function(result)
        currentTheme = noctalia.string.trim(result.stdout or "")
        publishThemes(query, filter)
      end)
    end
    publishThemes(query, filter)
    return
  end

  local rows = {}
  for _, e in ENTRIES do
    if text == "" or e.title:lower():find(text, 1, true) or e.id:find(text, 1, true) then
      local title, subtitle, glyph = e.title, e.subtitle, e.glyph
      if e.id == "lid-awake" then
        -- Zustand = Existenz des logind-Drop-ins (siehe bin/lid-awake), bei jedem Öffnen neu gelesen
        if noctalia.readFile(LID_DROPIN) then
          title = "Zuklappen weiterlaufen: AN"
          subtitle = "Zugeklappt läuft alles weiter – Enter schaltet aus (sudo)"
          glyph = "device-laptop"
        else
          title = "Zuklappen weiterlaufen: AUS"
          subtitle = "Zuklappen = Suspend – Enter schaltet ein (sudo)"
          glyph = "device-laptop-off"
        end
      end
      table.insert(rows, { id = e.id, title = title, subtitle = subtitle, glyph = glyph, query = e.query })
    end
  end
  launcher.setResults(query, rows)
end

function onActivate(id)
  local source, name = id:match("^(%a+):(.+)$")
  if source then
    noctalia.runAsync({ "noctalia", "msg", "color-scheme-set", source, name })
    return
  end

  for _, e in ENTRIES do
    if e.id == id then
      -- ohne Callback = losgelöst starten; der Launcher schließt sich danach
      noctalia.runAsync({ "kitty", "--class", "pkg-menu", "--title", e.title, "-e", "env", "PKG_WAIT=1", BIN .. id })
      return
    end
  end
end
