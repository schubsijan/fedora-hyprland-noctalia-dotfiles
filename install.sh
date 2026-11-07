#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%s)"

echo "==> Pakete installieren (install/packages.txt)"
mapfile -t PACKAGES < <(grep -vE '^\s*(#|$)' "$REPO_DIR/install/packages.txt")
sudo dnf install -y "${PACKAGES[@]}"

# Auswahl gleich am Anfang (fzf ist jetzt da), installiert wird erst ganz am Ende –
# danach läuft das Skript also ohne weitere Fragen durch.
echo "==> Optionale Programme auswählen (install/optional.txt)"
source "$REPO_DIR/install/lib/optional.sh"
optional_select

echo "==> Autologin"
source "$REPO_DIR/install/lib/autologin.sh"
autologin_select

# Ein stow-Paket pro Programm unter home/, jedes spiegelt $HOME
# (z.B. home/hypr/.config/hypr/…, home/noctalia/.local/state/noctalia/…).
# Neues Programm = neuer Ordner unter home/, hier muss nichts ergänzt werden.
STOW_DIR="$REPO_DIR/home"
mapfile -t STOW_PACKAGES < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

backup_conflicts() {
    local pkg f dest
    for pkg in "${STOW_PACKAGES[@]}"; do
        while IFS= read -r -d '' f; do
            dest="$HOME/${f#"$STOW_DIR/$pkg"/}"
            if [ -e "$dest" ] && [ ! -L "$dest" ]; then
                mv "$dest" "$dest.bak.$STAMP"
                echo "    backup: $dest -> $dest.bak.$STAMP"
            elif [ -L "$dest" ] && [ ! "$dest" -ef "$f" ]; then
                # Nur falsche Links entfernen: Würden auch korrekte kurz fehlen, lädt ein
                # laufendes Hyprland die Config neu und findet seine Module nicht.
                rm "$dest"
            fi
        done < <(find "$STOW_DIR/$pkg" \( -type f -o -type l \) -print0)
    done
}

echo "==> Home-Pfade an $HOME anpassen"
source "$REPO_DIR/install/lib/homepaths.sh"
homepaths_fix "$STOW_DIR"

# --no-folding: immer einzelne Datei-Symlinks, nie ganze Verzeichnisse verlinken
echo "==> stow: home/{${STOW_PACKAGES[*]}} -> ~"
backup_conflicts
stow --no-folding --dir="$STOW_DIR" --target="$HOME" "${STOW_PACKAGES[@]}"

# Wallpaper: ganzes Verzeichnis verlinken, damit neue Bilder automatisch im Repo landen.
# Bewusst ohne backup_conflicts: Es würde die Dateien durch den Link hindurch als
# Konflikte sehen und im Repo umbenennen.
echo "==> wallpapers -> ~/Pictures/Wallpapers"
WALLPAPER_LINK="$HOME/Pictures/Wallpapers"
if [ ! "$WALLPAPER_LINK" -ef "$REPO_DIR/wallpapers" ]; then
    mkdir -p "$HOME/Pictures"
    if [ -e "$WALLPAPER_LINK" ] || [ -L "$WALLPAPER_LINK" ]; then
        mv "$WALLPAPER_LINK" "$WALLPAPER_LINK.bak.$STAMP"
        echo "    backup: $WALLPAPER_LINK -> $WALLPAPER_LINK.bak.$STAMP"
    fi
    ln -sr "$REPO_DIR/wallpapers" "$WALLPAPER_LINK"
fi

echo "==> system -> / (sudo install)"
source "$REPO_DIR/install/lib/system.sh"
system_install

if [ "$AUTOLOGIN_SELECTED" -eq 1 ]; then
    echo "==> Autologin einrichten"
    autologin_apply
fi

if [ ${#OPTIONAL_SELECTED[@]} -gt 0 ]; then
    echo "==> Optionale Programme installieren"
    optional_install
fi

# Falls Hyprland während des Stow-Laufs eine halbfertige Config geladen hat
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "==> Hyprland-Config neu laden"
    hyprctl reload
fi

echo "==> Fertig. Änderungen mit 'git -C $REPO_DIR status' prüfen."
