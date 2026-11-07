# Kontext für Claude

Persönliche Dotfiles: **Fedora 44 + Hyprland (0.56, Lua-Config) + Noctalia Shell**.
Basis ist minimaDots (Hyprland, Noctalia, greetd); dieses Repo liegt obendrauf.
Kommunikation mit dem User auf **Deutsch**, Kommentare in Configs ebenfalls auf Deutsch.

## Deployment

- Repo-Pfad: `~/fedora-hyprland-noctalia-dotfiles`. Bisher **kein git-Repo initialisiert**.
- Struktur: `home/<programm>/` = ein **stow-Paket pro Programm**, das `$HOME` spiegelt
  (z.B. `home/hypr/.config/hypr/…`, `home/noctalia/.local/state/noctalia/…`, `home/bin/.local/bin/…`).
  `install.sh` verlinkt alle Pakete mit **einem** `stow --no-folding --dir=home --target=$HOME` (einzelne
  Datei-Symlinks, keine Verzeichnis-Symlinks). Neues Programm = neuer Ordner unter `home/`, install.sh bleibt unverändert.
- **Neue Datei angelegt → Symlink muss existieren**, sonst bricht z.B. ein `require`. Am einfachsten
  `stow --no-folding -d ~/fedora-hyprland-noctalia-dotfiles/home -t ~ <paket>` (oder `./install.sh` erneut laufen lassen).
- Ausnahme `wallpapers/`: `~/Pictures/Wallpapers` ist ein **Verzeichnis-Symlink** (von install.sh per `ln`, nicht stow),
  neue Bilder landen also automatisch im Repo. Nicht durch `backup_conflicts` schicken, das würde die Bilder umbenennen.
- `system/` spiegelt `/` (z.B. `system/etc/dnf/...`) und wird von `install/lib/system.sh` per `sudo install`
  **kopiert** (nicht verlinkt) – nach Änderungen erneut kopieren. Braucht ein Bereich danach eine Aktion
  (udev neu laden, initramfs bauen), dort in `SYSTEM_HOOKS` eintragen statt install.sh zu erweitern.
- Absolute Home-Pfade (`/home/schubsi/…`, z.B. in Noctalia-`settings.toml`) dürfen im Repo stehen:
  `install/lib/homepaths.sh` ersetzt sie vor dem stow-Lauf durch das `$HOME` des installierenden Benutzers.
  In Configs trotzdem `~`/`$HOME` bevorzugen, wo das Programm es versteht.
- `install/` enthält nur, was install.sh braucht: `packages.txt` (Pflicht), `optional.txt`, `optional/<name>.sh`, `lib/`.
- `*.bak.<timestamp>` in `~/.config/hypr` sind alte Backups von install.sh, nicht anfassen.

## Hyprland-Config (`home/hypr/.config/hypr/`)

Hyprland nutzt die **neue Lua-Config** (`hyprland.lua`), keine `hyprland.conf`-Syntax.
- API-Referenz/Stubs: `/usr/share/hypr/stubs/hl.meta.lua`, Beispiel: `/usr/share/hypr/hyprland.lua`.
  Dispatcher-Argumente notfalls per `strings $(which Hyprland) | grep "hl.window.move"` o.ä. finden.
- Wichtige API: `hl.bind(key, dispatcher_or_function, { description = ... })`, `hl.dsp.*`
  (`window`, `group`, `workspace`, `focus`, `layout`, `exec_cmd`), `hl.config({...})`,
  `hl.window_rule`, `hl.workspace_rule`, `hl.get_active_window()`, `hl.dispatch(...)`.
- `description` in Binds ist Pflicht-Stil — speist das Noctalia-Cheatsheet.
- Modular aufgeteilt, ein Thema pro Datei:
  - `hyprland.lua` – lädt Module via `require`; neue Module **sowohl** in die
    `package.loaded`-Reset-Liste **als auch** als `require(...)` eintragen.
  - `keybind.lua` – allgemeine Binds (Apps, Fokus HJKL, Resize Pfeile, Workspaces, Media)
  - `scrolling.lua` – Scrolling/dwindle-Layout-Umschaltung (SUPER+U), colresize (SUPER+R)
  - `grouping.lua` – Gruppen (SUPER+W/A/S/D gruppieren, N/P navigieren, Ü auflösen)
  - `minecraft.lua` – dreht die F-Tastenreihe um, solange Minecraft fokussiert ist (Messwerte im Dateikopf)
  - `windowrules.lua`, `startup.lua` (env + exec_once), `inputs.lua` (Layout `de`),
    `monitors.lua`, `animations.lua`, `themes/theme.lua`
  - `noctalia.lua` – **von Noctalia generiert** (Farben), nicht manuell editieren.
  - `Scripts/` – Shell-Helfer (Screenshots via satty/hyprshot, Workspace etc.)
- Stil: `mainMod = "SUPER"`, Keys als `("%s + X"):format(mainMod)`, Tabs/4 Spaces gemischt
  (bestehenden Stil der jeweiligen Datei übernehmen).
- Vor neuen Binds **auf Konflikte prüfen** (`grep -n "hl.bind" home/hypr/.config/hypr/*.lua`) und
  Konflikte dem User melden. Umlaute als xkb-Keysym (`udiaeresis`, `odiaeresis`, …).
- Nach Änderungen testen: `hyprctl reload && hyprctl configerrors`, Binds prüfen mit `hyprctl binds -j`.

## Weitere Komponenten

- **Noctalia** ist Bar, Launcher, Notification-Daemon (kein swaync) — Steuerung via
  `noctalia msg ...` (z.B. `panel-toggle launcher`, `notification-show '...'`, `volume-up 5%`).
  Aktive Settings: `home/noctalia/.local/state/noctalia/settings.toml` (hat Vorrang). Noctalia führt zusätzlich **alle** `*.toml` aus
  `~/.config/noctalia/` zusammen, also auch `noctalia-full-config.toml` und `zennotes-template.toml`.
- **ZenNotes-Theme:** eigenes Noctalia-Template (`home/noctalia/.config/noctalia/zennotes-template.toml`, Vorlage in
  `templates/` daneben) erzeugt `~/.config/zennotes/themes/noctalia/theme.css` (nicht im Repo).
- Terminal **kitty**, Shell **fish** + **starship**, Browser **Helium** (Chromium-basiert, `helium.desktop`), Dateimanager thunar.
- **Standard-Programme:** `home/xdg/.config/hyprland-mimeapps.list` (desktop-spezifisch, Vorrang vor `mimeapps.list`).
  Tools/GUI schreiben nur in `~/.config/mimeapps.list` (lokal, nicht im Repo) – dauerhafte Defaults daher in der Hyprland-Datei pflegen.
- Offene Aufgaben: `TODO.md` (abhaken wenn erledigt).
- Autologin: `install/lib/autologin.sh` fragt in install.sh nach (nur auf verschlüsselten Systemen), `greetd-autologin` (`home/bin/`)
  schreibt `/etc/greetd/config.toml`. Der `login`-Schlüsselbund hat dann kein Passwort; vorhandene nie überschreiben.
- `lid-awake` (`home/bin/`, Eintrag im pkg-menu): schaltet per sudo `/etc/systemd/logind.conf.d/50-lid-awake.conf`
  (Zuklappen ignorieren) an/aus und lädt logind neu. Bewusst nicht in `system/`, da Laufzeit-Zustand.
- **Härtung** (über `system/` + Hooks in `install/lib/system.sh`): SSH-Server aus und Port 22 zu
  (`system-preset/10-dotfiles.preset` + `_system_hook_sshd`, läuft bei jedem Aufruf), LLMNR aus
  (`resolved.conf.d/10-no-llmnr.conf`). Git/GitHub läuft über HTTPS (`gh`), braucht kein sshd.
  Secure Boot bewusst aus (Limine/Omarchy-Dualboot).
- `boot-fedora-first` (`home/bin/`): nur für diesen Rechner (feste UUID der Limine-Partition).
- Optionale Programme: `install/optional.txt` (Quellen `dnf`, `copr:<owner>/<projekt>`, `flatpak`, `script`).
  install.sh fragt sie per fzf ab (`install/lib/optional.sh`) und installiert sie am Ende. `script <name>` führt
  `install/optional/<name>.sh` aus – nur für Programme, die sich selbst aktualisieren, da `pkg-update` sie nicht kennt.
  Solche Skripte müssen `--status` (Exit 0 + Infozeile, wenn installiert) und `--remove` können, dann listet `pkg-remove` sie.
