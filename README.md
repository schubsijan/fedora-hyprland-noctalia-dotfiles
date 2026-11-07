# fedora-hyprland-noctalia-dotfiles

Meine Dotfiles für Fedora 44 + Hyprland + Noctalia.
Basis: [minimaDots](https://gitlab.com/minimalinux/minimaDots) (fedora_install.sh) — dieses Repo kommt **obendrauf**.

## Frische Installation

<details>
<summary>Vorher: Fedora installieren und Platz auf der Platte schaffen (Dualboot)</summary>

Alles in diesem Abschnitt passiert **vor** minimaDots und diesen Dotfiles. Maßgeblich ist die
Anleitung von minimaDots, hier stehen nur Tipps zur Partitionierung.

**Ein Stick für alles: Ventoy + GParted Live**

Der Fedora-Installer kann vorhandene Partitionen nur eingeschränkt verkleinern, verschlüsselte
(LUKS) gar nicht. Statt eines zweiten Boot-Sticks für GParted einfach beide ISOs auf einen
[Ventoy](https://www.ventoy.net)-Stick legen:

1. Ventoy auf den Stick installieren (Linux: `sudo ./Ventoy2Disk.sh -i /dev/sdX`,
   Windows: `Ventoy2Disk.exe`). **Löscht den Stick.**
2. Das Fedora-ISO und das [GParted-Live](https://gparted.org/livecd.php)-ISO als normale
   Dateien auf den Stick kopieren.
3. Vom Stick booten und im Ventoy-Menü **GParted Live** wählen.
4. In GParted Platz freigeben:
   - **Unverschlüsselte Partition** (NTFS, ext4, btrfs): Rechtsklick → *Größe ändern/Verschieben*
     (*Resize/Move*).
   - **Verschlüsselte Partition** (LUKS, z.B. eine andere Linux-Installation): zuerst Rechtsklick →
     *Verschlüsselung öffnen* (*Open Encryption*) und Passphrase eingeben, danach
     *Größe ändern/Verschieben*. GParted verkleinert Dateisystem, LUKS-Container und Partition
     in der richtigen Reihenfolge.
   - Mit *Alle Vorgänge ausführen* (*Apply All Operations*, grüner Haken) anwenden.
5. Neu starten, im Ventoy-Menü das **Fedora-ISO** wählen und Fedora installieren (siehe unten).

> [!WARNING]
> Vorher ein Backup machen. Bei **Windows** vorher in Windows den Schnellstart deaktivieren,
> BitLocker anhalten (falls aktiv) und Windows ganz herunterfahren, nicht im Ruhezustand.
> Sonst verweigert GParted das Verkleinern oder beschädigt die NTFS-Partition.

**Einstellungen im Fedora-Installer**

| Punkt | Einstellung |
|---|---|
| **Keyboard** | Deutsch (`de`) hinzufügen bzw. als Layout setzen |
| **Language Support** | zusätzlich **Deutsch** auswählen |
| **Time & Date** | *Region* **Europe**, *City* **Berlin**, **Automatic date & time** an |
| **Network & Host Name** | mit dem WLAN verbinden (zuerst, sonst klappt die Netzwerk-Quelle nicht) |
| **Installation Source** | **On the network**; darunter **Install the latest available software updates** |
| **Software Selection** | wie bei minimaDots: *Base Environment* **Fedora Custom Operating System**, rechts dazu **Common NetworkManager Submodules** und **Standard** |
| **Installation Destination** | Platte auswählen, *Storage Configuration* auf **Automatic**, **Encrypt my data** aktivieren. Der Installer nutzt dann nur den freien Platz und lässt die anderen Systeme in Ruhe |
| **Root Account** | **Disable root account** |
| **User Creation** | Benutzer anlegen, Passwort setzen und **Add administrative privileges to this user account** anhaken |

Danach *Begin Installation*, neu starten und mit minimaDots weitermachen.

</details>

```bash
# 1. minimaDots-Basis (Hyprland, Noctalia, greetd, Noctalia-Greeter)
#    -> siehe minimaDots fedora_install.sh

# 2. Dieses Repo klonen (öffentlich, keine GitHub-Anmeldung nötig)
git clone https://github.com/schubsijan/fedora-hyprland-noctalia-dotfiles.git ~/fedora-hyprland-noctalia-dotfiles
cd ~/fedora-hyprland-noctalia-dotfiles

# 3. Pakete + Symlinks
./install.sh
```

`install.sh` ist idempotent: bestehende echte Dateien werden gesichert
(`*.bak.<timestamp>`), Symlinks werden erneuert.

Nach den Pflichtpaketen fragt es per fzf ab, welche Programme aus
`install/optional.txt` installiert werden sollen (Tab: markieren, Enter: bestätigen,
Esc: keine). Installiert wird die Auswahl ganz am Ende. Weitere Programme einfach
in der Datei ergänzen, das Format steht oben darin.

Auf einem verschlüsselten System fragt es außerdem, ob Autologin eingerichtet werden soll
(Vorgabe: nein). Dann gibt man beim Start nur noch das Verschlüsselungspasswort ein.

- Ohne vorhandenen Schlüsselbund legt es einen ohne Passwort an. Am besten `install.sh` also
  **vor der ersten Anmeldung am Desktop** ausführen (z.B. von einer Textkonsole).
- Einen vorhandenen Schlüsselbund mit Passwort ändert es nicht. Das Passwort dann mit `seahorse` leeren.
- Der Schlüsselbund liegt dadurch im Klartext in `~/.local/share/keyrings`: nicht ins Repo
  aufnehmen und in Home-Backups ausschließen oder das Backup verschlüsseln.
- Später umschalten mit `greetd-autologin` bzw. `greetd-autologin off`.

### Nach der ersten Anmeldung

Diese Theme-Einstellungen kann `install.sh` nicht setzen. Noctalia braucht beim ersten Start Internet,
weil es die Palette und die Community-Templates herunterlädt.

- [ ] **Git & GitHub:** `git-setup` ausführen. Es meldet dich per Browser bei GitHub an, richtet
  `git push` über HTTPS ein und setzt Name und E-Mail für Commits (Vorschlag: die Noreply-Adresse
  von GitHub, damit die echte Adresse nicht in öffentlichen Commits steht).

- [ ] **Helium** (falls installiert): Die Farbrichtlinie liegt außerhalb des Repos in
  `/etc/chromium/policies/managed/noctalia-color.json`. Einmal in einem normalen Terminal ausführen
  (fragt nach dem `sudo`-Passwort):

  ```bash
  bash ~/.local/state/noctalia/community-templates/chromium-based/apply.sh setup
  ```

- [ ] **Templates anwenden:** Beim ersten Start können einzelne Templates fehlschlagen, weil ihre
  Dateien noch nicht geladen sind:

  ```bash
  noctalia msg templates-apply
  ```

- [ ] **Helium** neu starten und unter `helium://policy` prüfen, ob `BrowserThemeColor` gesetzt ist.
- [ ] **Claude Code** (falls installiert): `/theme` → `Noctalia`
- [ ] **Prism Launcher** (falls installiert): In den Einstellungen als Theme `Matugen` wählen.

## Struktur

| Pfad im Repo     | Ziel / Zweck |
|------------------|--------------|
| `home/<programm>/` | stow-Paket pro Programm, spiegelt `$HOME` (z.B. `home/hypr/.config/hypr/`). Wird komplett mit einem `stow`-Aufruf verlinkt, neue Programme = neuer Ordner |
| `home/bin/`      | eigene Befehle → `~/.local/bin` (`pkg-*`, `greetd-autologin`, `helium-backup`, …) |
| `home/noctalia/` | Noctalia: Config (`noctalia-full-config.toml`, Noctalia führt alle `*.toml` zusammen), Launcher-Plugin, ZenNotes-Template **und** aktive Settings (`.local/state/noctalia/settings.toml`) |
| `home/xdg/`      | Standard-Programme (`~/.config/hyprland-mimeapps.list`, hat Vorrang vor `mimeapps.list`) |
| `system/`        | spiegelt `/`, wird per `sudo install` **kopiert** (dnf, udev-Regel Touchscreen aus, Plymouth-Theme) |
| `install/`       | alles nur für `install.sh`: `packages.txt`, `optional.txt`, `optional/<name>.sh`, `lib/` |
| `wallpapers/`    | `~/Pictures/Wallpapers` (Verzeichnis-Symlink: neue Bilder landen automatisch im Repo) |

Übrige Pakete unter `home/`: fastfetch, fish, hypr, kitty, mise, nvim, qt6ct, starship, thunar, zennotes.

Nicht versioniert (bewusst): noctalia-Runtime-State (Clipboard, History,
`state.toml`), easyeffects, qt/gtk.

## Alltag

- Config geändert → `git add -u && git commit && git push`
- Abweichungen sehen → `git status` bzw. Symlinks prüfen mit `ls -l ~/.config/hypr`
- Repo auf neuen Rechner → clone + `./install.sh`

## Anmerkungen

- Keybinds laufen über Hyprland (`~/.config/hypr/keybind.lua`) und rufen
  `noctalia msg …` auf; `description`-Felder speisen das Cheatsheet-Widget.
- `starship` wird über die Fedora-Reste installiert (die Config erwartet es in fish).

## Wallpaper

Die Bilder in `wallpapers/` sind nicht von mir, sondern stammen aus diesen Sammlungen:

- [linuxdotexe/nordic-wallpapers](https://github.com/linuxdotexe/nordic-wallpapers): dort aus verschiedenen Quellen gesammelt
  (u.a. Unsplash, Reddit, wallhaven) und mit [ImageGoNord](https://ign.schrodinger-hat.it/) eingefärbt
- [everforest_walls](https://box.apeiros.xyz/public/everforest_walls/)

Die Rechte liegen bei den jeweiligen Urhebern. Wer ein Bild entfernt haben möchte, kann gern ein Issue aufmachen.
