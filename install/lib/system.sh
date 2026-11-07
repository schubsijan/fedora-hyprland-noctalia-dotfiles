# install/lib/system.sh – system/ nach / kopieren und betroffene Dienste aktualisieren
# Wird von install.sh per "source" geladen:
#   system_install   kopiert system/ (root-eigen, daher kopieren statt verlinken)
#                    und ruft danach die passenden Hooks auf

_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/system"

# Pfad-Präfix -> Hook. Jeder Hook läuft einmal am Ende und bekommt 1, wenn sich unter
# dem Präfix etwas geändert hat, sonst 0. Neues Systemfeature mit Nacharbeit?
# Hier eine Zeile und unten eine Funktion ergänzen – die Kopierschleife bleibt gleich.
declare -A SYSTEM_HOOKS=(
    [/etc/udev/rules.d/]=_system_hook_udev
    [/usr/share/plymouth/themes/]=_system_hook_plymouth
    [/etc/systemd/system/]=_system_hook_systemd
    [/etc/systemd/resolved.conf.d/]=_system_hook_resolved
    [/etc/systemd/system-preset/]=_system_hook_sshd
)

# udev-Regeln (z.B. Touchscreen aus) sofort aktivieren statt erst nach Neustart
_system_hook_udev() {
    [ "$1" -eq 1 ] || return 0
    echo "==> udev-Regeln neu laden"
    sudo udevadm control --reload-rules
    sudo udevadm trigger --action=change
}

# Boot-Splash/LUKS-Passwortabfrage. Das Theme steckt im initramfs, daher nur bei
# Änderungen (oder falls ein anderes Theme aktiv ist) neu bauen – dracut dauert etwas.
_system_hook_plymouth() {
    local theme="noctalia"
    [ "$1" -eq 1 ] || [ "$(plymouth-set-default-theme)" != "$theme" ] || return 0
    echo "==> Plymouth-Theme '$theme' setzen und initramfs neu bauen"
    sudo plymouth-set-default-theme -R "$theme"
}

# Unit-Dateien/Drop-ins (z.B. plymouth-quit mit --retain-splash) neu einlesen
_system_hook_systemd() {
    [ "$1" -eq 1 ] || return 0
    echo "==> systemd-Units neu laden"
    sudo systemctl daemon-reload
}

# DNS-Resolver-Drop-ins (z.B. LLMNR aus) übernehmen
_system_hook_resolved() {
    [ "$1" -eq 1 ] || return 0
    echo "==> systemd-resolved neu starten"
    sudo systemctl restart systemd-resolved
}

# SSH-Server aus und Port 22 in der Firewall zu. Läuft bei jedem Aufruf (nicht nur bei
# Änderungen), prüft aber erst den Zustand – ist alles schon aus, passiert nichts.
_system_hook_sshd() {
    if systemctl is-enabled --quiet sshd 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
        echo "==> SSH-Server deaktivieren"
        sudo systemctl disable --now sshd
    fi
    if systemctl is-active --quiet firewalld \
        && sudo firewall-cmd --permanent --query-service=ssh >/dev/null 2>&1; then
        echo "==> SSH in der Firewall schließen"
        sudo firewall-cmd --permanent --remove-service=ssh >/dev/null
        sudo firewall-cmd --reload >/dev/null
    fi
}

system_install() {
    local -A changed=()
    local f rel prefix
    while IFS= read -r -d '' f; do
        rel="${f#"$_SYSTEM_DIR"}"
        for prefix in "${!SYSTEM_HOOKS[@]}"; do
            if [[ "$rel" == "$prefix"* ]] && ! cmp -s "$f" "$rel"; then
                changed[$prefix]=1
            fi
        done
        sudo install -Dm644 "$f" "$rel"
        echo "    $rel"
    done < <(find "$_SYSTEM_DIR" -type f -print0)

    for prefix in "${!SYSTEM_HOOKS[@]}"; do
        "${SYSTEM_HOOKS[$prefix]}" "${changed[$prefix]:-0}"
    done
}
