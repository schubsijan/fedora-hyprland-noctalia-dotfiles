# install/lib/autologin.sh – Autologin und Schlüsselbund ohne Passwort einrichten
# Wird von install.sh per "source" geladen:
#   autologin_select   fragt nach, ob eingerichtet werden soll (setzt AUTOLOGIN_SELECTED)
#   autologin_apply    richtet den Schlüsselbund und den Autologin ein

_AUTOLOGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTOLOGIN_SELECTED=0

# Auch für verschachtelte Aufbauten wie LVM auf LUKS: prüft alle Geräte unter dem Root-Dateisystem
_autologin_root_encrypted() {
    local source
    source="$(findmnt -nvo SOURCE /)" || return 1
    lsblk -s -no TYPE "$source" 2>/dev/null | grep -qx crypt
}

# Vorhandene Schlüsselbunde werden nie überschrieben, sonst wären die Geheimnisse darin verloren
_autologin_keyring() {
    local dir="$HOME/.local/share/keyrings"
    local file="$dir/login.keyring"
    local others=("$dir"/*.keyring)

    if [ -e "$file" ]; then
        if [ "$(head -c 9 "$file")" = "[keyring]" ]; then
            echo "    Schlüsselbund hat bereits kein Passwort."
            return 0
        fi
    elif [ ! -e "${others[0]}" ]; then
        (
            umask 077
            mkdir -p "$dir"
            cat >"$file" <<EOF
[keyring]
display-name=Login
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF
        )
        echo "    Schlüsselbund ohne Passwort angelegt."
        return 0
    fi

    echo "    Es gibt schon einen Schlüsselbund, er bleibt unverändert."
    echo "    Hat er ein Passwort, lässt es sich mit 'seahorse' leeren, sonst fragt der Browser danach."
}

autologin_select() {
    AUTOLOGIN_SELECTED=0
    if [ "$EUID" -eq 0 ]; then
        echo "    Läuft als root, überspringe."
        return 0
    fi
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        echo "    Kein interaktives Terminal, überspringe."
        return 0
    fi
    if [ ! -f /etc/greetd/config.toml ] || [ ! -x /usr/sbin/noctalia-greeter-session ]; then
        echo "    greetd oder Noctalia-Greeter fehlt, überspringe."
        return 0
    fi
    if grep -q '^\[initial_session\]' /etc/greetd/config.toml; then
        echo "    Autologin ist bereits eingerichtet."
        return 0
    fi
    if ! _autologin_root_encrypted; then
        echo "    System ist nicht verschlüsselt, Autologin wird nicht angeboten."
        return 0
    fi

    echo "    Du gibst beim Start nur noch das Verschlüsselungspasswort ein."
    echo "    Der Schlüsselbund liegt dann im Klartext in ~/.local/share/keyrings,"
    echo "    geschützt nur durch die Festplattenverschlüsselung."
    local answer=""
    read -r -p "    Einrichten? [j/N] " answer || true
    case "$answer" in
        j | J | ja | Ja | JA) AUTOLOGIN_SELECTED=1 ;;
        *) echo "    Nicht eingerichtet." ;;
    esac
}

# Ein Fehler hier bricht die Installation nicht ab, der Login-Screen funktioniert dann weiter
autologin_apply() {
    [ "$AUTOLOGIN_SELECTED" -eq 1 ] || return 0
    _autologin_keyring
    if ! "$_AUTOLOGIN_ROOT/home/bin/.local/bin/greetd-autologin"; then
        echo "    Autologin konnte nicht eingerichtet werden."
    fi
}
