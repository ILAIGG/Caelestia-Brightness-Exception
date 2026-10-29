#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR=${XDG_CONFIG_HOME:-"$HOME/.config"}/quickshell/caelestia
STATE_DIR=${XDG_STATE_HOME:-"$HOME/.local/state"}/caelestia-brightness-exception
MARKER=$CONFIG_DIR/.brightness-exception.json
brightness_backup=$STATE_DIR/Brightness.qml.backup
shell_backup=$STATE_DIR/shell.qml.backup

if [[ ! -e $MARKER ]]; then
    printf 'Brightness exception is not installed.\n' >&2
    exit 1
fi

if [[ ! -f $brightness_backup || ! -f $shell_backup ]]; then
    printf 'Cannot restore configuration; backups are missing from %s\n' "$STATE_DIR" >&2
    exit 1
fi

cp -p -- "$brightness_backup" "$CONFIG_DIR/services/Brightness.qml"
cp -p -- "$shell_backup" "$CONFIG_DIR/shell.qml"
rm -f -- "$CONFIG_DIR/BrightnessException.qml" \
    "$CONFIG_DIR/BrightnessExceptionWindow.qml" "$MARKER" \
    "$brightness_backup" "$shell_backup"
rmdir --ignore-fail-on-non-empty -- "$STATE_DIR"

printf 'Restored the original Caelestia files in %s\n' "$CONFIG_DIR"