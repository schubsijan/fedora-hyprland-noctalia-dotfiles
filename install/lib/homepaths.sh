# Fremde Home-Pfade in den stow-Paketen an das eigene $HOME anpassen.
#
# Noctalia (settings.toml), qt6ct und fish speichern absolute Pfade, Noctalia schreibt sie bei jedem
# Wallpaper-Wechsel neu. Im Repo stehen daher die Pfade des Repo-Besitzers (/home/<name>/…). Wer das
# Repo unter einem anderen Benutzernamen klont, bekäme sonst kaputte Wallpaper-, Plugin- und
# Theme-Pfade. Für den Besitzer selbst findet die Funktion nichts und ändert nichts.

# $1: Verzeichnis der stow-Pakete (home/)
homepaths_fix() {
    local dir=$1 own="$HOME/" old file
    while IFS= read -r old; do
        # Eigener Pfad, auch wenn $HOME z.B. /var/home/<name> ist
        [[ $own == *"$old" ]] && continue
        while IFS= read -r -d '' file; do
            sed -i "s|${old//./\\.}|${own//&/\\&}|g" "$file"
            echo "    ${file#"$dir"/}: $old -> $own"
        done < <(grep -rlZIF -- "$old" "$dir")
    done < <(grep -rhoIE '/home/[A-Za-z0-9._-]+/' "$dir" | sort -u)
}
