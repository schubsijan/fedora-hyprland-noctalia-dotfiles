#!/usr/bin/env bash
# stick-backup aus dem Git-Repo bauen und nach ~/.local/bin installieren.
# Spiegelt ausgewählte Ordner auf einen USB-Stick (exFAT); Aufruf über das /pkg-Menü
# ("Backup auf USB-Stick", siehe bin/stick-backup-run).
#
#   stick-backup.sh            installieren bzw. auf den neuesten Tag aktualisieren
#   stick-backup.sh --update   nur aktualisieren, wenn installiert (wird von pkg-update aufgerufen)
#   stick-backup.sh --status   Exit 0 und eine Infozeile, wenn installiert (für pkg-remove)
#   stick-backup.sh --remove   Programm entfernen, die Daten auf dem Stick bleiben erhalten

set -euo pipefail

REPO="github.com/schubsijan/stick-backup"
BIN="$HOME/.local/bin/stick-backup"

case "${1:-}" in
    --status)
        [ -x "$BIN" ] || exit 1
        echo "$("$BIN" --version) (go install aus $REPO)"
        exit 0
        ;;
    --remove)
        rm -f "$BIN"
        echo "    stick-backup ist entfernt. Die Daten auf dem Stick bleiben erhalten."
        exit 0
        ;;
    --update)
        if [ ! -x "$BIN" ]; then
            echo "    stick-backup ist nicht installiert, nichts zu aktualisieren."
            exit 0
        fi
        ;;
esac

OLD=""
[ -x "$BIN" ] && OLD="$("$BIN" --version 2>/dev/null || true)"

if ! command -v go >/dev/null; then
    echo "    Go fehlt (sudo dnf install golang), stick-backup wird nicht gebaut." >&2
    exit 1
fi
# Zur Laufzeit gebraucht: rsync (Kopieren), udisksctl (Stick einhängen/auswerfen)
for cmd in rsync udisksctl; do
    command -v "$cmd" >/dev/null || echo "    Hinweis: $cmd fehlt, stick-backup braucht es zur Laufzeit." >&2
done

echo "    Baue stick-backup aus $REPO …"
mkdir -p "$(dirname "$BIN")"
# Statisches Binary; @latest = neuester Tag (der Go-Proxy kennt neue Tags evtl. erst nach ein paar Minuten)
CGO_ENABLED=0 GOBIN="$(dirname "$BIN")" go install "$REPO/cmd/stick-backup@latest"
NEW="$("$BIN" --version)"
if [ -z "$OLD" ]; then
    echo "    stick-backup ist installiert: $BIN ($NEW)"
elif [ "$OLD" = "$NEW" ]; then
    echo "    stick-backup ist aktuell ($NEW)."
else
    echo "    stick-backup aktualisiert: $OLD → $NEW"
fi
