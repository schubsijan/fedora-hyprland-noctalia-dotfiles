#!/usr/bin/env bash
# Zotero aus dem offiziellen Tarball nach ~/.local/opt/zotero installieren.
# Das Verzeichnis gehört dem Benutzer, damit Zoteros eingebauter Updater schreiben darf –
# deshalb hier kein Update-Mechanismus, und eine vorhandene Installation bleibt unangetastet.
#
#   zotero.sh            installieren
#   zotero.sh --status   Exit 0 und eine Infozeile, wenn installiert (für pkg-remove)
#   zotero.sh --remove   Programm und Starter entfernen, die Bibliothek bleibt erhalten

set -euo pipefail

URL="https://www.zotero.org/download/client/dl?channel=release&platform=linux-$(uname -m)"
TARGET="$HOME/.local/opt/zotero"
DESKTOP="$HOME/.local/share/applications/zotero.desktop"

case "${1:-}" in
    --status)
        [ -x "$TARGET/zotero" ] || exit 1
        version="$(sed -n 's/^Version=//p' "$TARGET/app/application.ini" 2>/dev/null || true)"
        echo "Zotero ${version:-?} (Tarball in ~/.local/opt/zotero, aktualisiert sich selbst)"
        exit 0
        ;;
    --remove)
        rm -rf "$TARGET"
        rm -f "$DESKTOP"
        command -v update-desktop-database >/dev/null && update-desktop-database "$(dirname "$DESKTOP")" || true
        echo "    Zotero ist entfernt. Deine Bibliothek bleibt erhalten: ~/Zotero und ~/.zotero"
        exit 0
        ;;
esac

if [ -x "$TARGET/zotero" ]; then
    echo "    Zotero ist schon installiert ($TARGET)."
else
    mkdir -p "$(dirname "$TARGET")"
    TMP="$(mktemp -d "$TARGET.XXXXXX")"
    trap 'rm -rf "$TMP"' EXIT

    echo "    Lade Zotero herunter …"
    curl -fL --progress-bar "$URL" | tar -xJ --strip-components=1 -C "$TMP"
    chmod 755 "$TMP"    # mktemp legt das Verzeichnis mit 700 an
    rm -rf "$TARGET"
    mv "$TMP" "$TARGET"
fi

# Eigener Starter statt Symlink: Zoteros Original löst seinen Pfad zur Laufzeit auf, und ein
# Update könnte es überschreiben. Der Pfad zum Icon muss ohnehin absolut eingetragen sein.
mkdir -p "$(dirname "$DESKTOP")"
sed -e "s|^Exec=.*|Exec=\"$TARGET/zotero\" -url %U|" \
    -e "s|^Icon=.*|Icon=$TARGET/icons/icon128.png|" \
    "$TARGET/zotero.desktop" >"$DESKTOP"
command -v update-desktop-database >/dev/null && update-desktop-database "$(dirname "$DESKTOP")" || true

echo "    Zotero ist installiert: $TARGET"
