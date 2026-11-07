# install/lib/optional.sh – optionale Programme aus install/optional.txt auswählen und installieren
# Wird von install.sh per "source" geladen:
#   optional_select    fragt die Auswahl ab (setzt OPTIONAL_SELECTED)
#   optional_install   installiert die Auswahl, ein Fehler bricht den Rest nicht ab

# Zeigt auf install/ (dort liegen optional.txt und optional/<name>.sh)
_OPTIONAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_OPTIONAL_LIST="$_OPTIONAL_ROOT/optional.txt"
OPTIONAL_SELECTED=()    # Einträge im Format "<quelle> <paket>"

# Gibt pro Eintrag eine Zeile aus: quelle<TAB>paket<TAB>gruppe<TAB>beschreibung
_optional_parse() {
    local line source pkg rest group="-"
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^##[[:space:]]*(.*[^[:space:]]) ]]; then
            group="${BASH_REMATCH[1]}"
            continue
        fi
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue

        read -r source pkg rest <<<"$line"
        case "$source" in
            dnf | flatpak | script | copr:*/*) ;;
            *)
                echo "    Übersprungen, unbekannte Quelle: $line" >&2
                continue
                ;;
        esac
        if [ -z "$pkg" ] || [[ "$pkg" == \#* ]]; then
            echo "    Übersprungen, kein Paket angegeben: $line" >&2
            continue
        fi
        rest="${rest#\#}"
        rest="${rest#"${rest%%[![:space:]]*}"}"
        printf '%s\t%s\t%s\t%s\n' "$source" "$pkg" "$group" "$rest"
    done <"$_OPTIONAL_LIST"
}

optional_select() {
    OPTIONAL_SELECTED=()
    if [ ! -f "$_OPTIONAL_LIST" ]; then
        echo "    install/optional.txt nicht gefunden, überspringe."
        return 0
    fi
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        echo "    Kein interaktives Terminal, überspringe die Auswahl."
        return 0
    fi

    local entries chosen source pkg
    entries="$(_optional_parse)"
    if [ -z "$entries" ]; then
        echo "    Keine Einträge in install/optional.txt."
        return 0
    fi

    # Sichtbar sind nur Gruppe, Paket und Beschreibung; Quelle und Paket werden danach ausgelesen.
    # fzf endet bei Esc mit Exit-Code 130 – das heißt hier nur "nichts gewählt".
    chosen="$(
        awk -F'\t' '{ printf "%s\t%s\t%-14s %-34s %s\n", $1, $2, $3, $2, $4 }' <<<"$entries" |
            fzf --multi --reverse --height 80% \
                --delimiter $'\t' --with-nth 3 \
                --prompt "optional> " \
                --header "Tab: markieren · Strg+A: alle · Enter: bestätigen (ohne Markierung: aktuelle Zeile) · Esc: nichts installieren" \
                --bind 'ctrl-a:toggle-all' \
                --color 'pointer:green,marker:green'
    )" || true

    while IFS=$'\t' read -r source pkg _; do
        [ -n "$source" ] && OPTIONAL_SELECTED+=("$source $pkg")
    done <<<"$chosen"

    if [ ${#OPTIONAL_SELECTED[@]} -eq 0 ]; then
        echo "    Nichts ausgewählt."
    else
        echo "    Wird am Ende installiert:"
        printf '      %s\n' "${OPTIONAL_SELECTED[@]}"
    fi
}

optional_install() {
    [ ${#OPTIONAL_SELECTED[@]} -gt 0 ] || return 0

    local entry source pkg project
    local rpm_pkgs=() flatpaks=() scripts=() failed=() seen_coprs=() failed_coprs=()

    for entry in "${OPTIONAL_SELECTED[@]}"; do
        read -r source pkg <<<"$entry"
        case "$source" in
            dnf) rpm_pkgs+=("$pkg") ;;
            flatpak) flatpaks+=("$pkg") ;;
            script) scripts+=("$pkg") ;;
            copr:*)
                project="${source#copr:}"
                if [[ " ${failed_coprs[*]} " == *" $project "* ]]; then
                    failed+=("$pkg (COPR $project)")
                    continue
                fi
                if [[ " ${seen_coprs[*]} " != *" $project "* ]]; then
                    if ! sudo dnf copr enable -y "$project"; then
                        failed_coprs+=("$project")
                        failed+=("$pkg (COPR $project)")
                        continue
                    fi
                    seen_coprs+=("$project")
                fi
                rpm_pkgs+=("$pkg")
                ;;
        esac
    done

    # Flatpak fehlt auf dem System? Dann über dnf gleich mit installieren.
    if [ ${#flatpaks[@]} -gt 0 ] && ! command -v flatpak >/dev/null; then
        rpm_pkgs+=(flatpak)
    fi

    # Alle RPMs in einer Transaktion; --skip-unavailable, damit ein fehlendes Paket
    # nicht die anderen mitreißt. Was wirklich da ist, prüft danach rpm.
    if [ ${#rpm_pkgs[@]} -gt 0 ]; then
        sudo dnf install -y --skip-unavailable "${rpm_pkgs[@]}" || true
        for pkg in "${rpm_pkgs[@]}"; do
            rpm -q --whatprovides "$pkg" >/dev/null 2>&1 || failed+=("$pkg (dnf)")
        done
    fi

    # System-Installation, wie in pkg-update
    if [ ${#flatpaks[@]} -gt 0 ]; then
        if sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
            for pkg in "${flatpaks[@]}"; do
                sudo flatpak install -y --or-update flathub "$pkg" || failed+=("$pkg (flatpak)")
            done
        else
            for pkg in "${flatpaks[@]}"; do failed+=("$pkg (flatpak: kein flathub)"); done
        fi
    fi

    for pkg in "${scripts[@]}"; do
        if [ -f "$_OPTIONAL_ROOT/optional/$pkg.sh" ]; then
            bash "$_OPTIONAL_ROOT/optional/$pkg.sh" || failed+=("$pkg (script)")
        else
            failed+=("$pkg (optional/$pkg.sh fehlt)")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        echo "    Nicht installiert:"
        printf '      %s\n' "${failed[@]}"
    else
        echo "    Alle ausgewählten Programme sind installiert."
    fi
}
