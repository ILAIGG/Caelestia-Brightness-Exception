#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_DIR=${XDG_CONFIG_HOME:-"$HOME/.config"}/quickshell/caelestia
SYSTEM_CONFIG_DIR=/etc/xdg/quickshell/caelestia
STATE_DIR=${XDG_STATE_HOME:-"$HOME/.local/state"}/caelestia-brightness-exception
MARKER=$CONFIG_DIR/.brightness-exception.json

replace_once() {
    local file=$1 old=$2 new=$3 temporary
    temporary=$(mktemp "${file}.XXXXXX")
    cp -p -- "$file" "$temporary"
    if ! PATCH_OLD=$old PATCH_NEW=$new perl -0pi -e '
        my $count = () = /\Q$ENV{PATCH_OLD}\E/g;
        die "Expected one patch anchor, found $count\n" unless $count == 1;
        s/\Q$ENV{PATCH_OLD}\E/$ENV{PATCH_NEW}/;
    ' "$temporary"; then
        rm -f -- "$temporary"
        return 1
    fi
    mv -- "$temporary" "$file"
}

if [[ ! -d $SYSTEM_CONFIG_DIR ]]; then
    printf 'Caelestia shell not found: %s\n' "$SYSTEM_CONFIG_DIR" >&2
    exit 1
fi

if [[ -e $MARKER ]]; then
    printf 'Brightness exception is already installed.\n'
    exit 0
fi

if [[ ! -e $CONFIG_DIR ]]; then
    mkdir -p -- "$(dirname -- "$CONFIG_DIR")"
    cp -a -- "$SYSTEM_CONFIG_DIR" "$CONFIG_DIR"
fi

brightness_path=$CONFIG_DIR/services/Brightness.qml
shell_path=$CONFIG_DIR/shell.qml
if [[ ! -f $brightness_path || ! -f $shell_path ]]; then
    printf 'The local Caelestia configuration is missing required files.\n' >&2
    exit 1
fi

mkdir -p -- "$STATE_DIR"
brightness_backup=$STATE_DIR/Brightness.qml.backup
shell_backup=$STATE_DIR/shell.qml.backup
if [[ -e $brightness_backup || -e $shell_backup ]]; then
    printf 'Existing backup found in %s; inspect it before installing.\n' "$STATE_DIR" >&2
    exit 1
fi

brightness_stage=$(mktemp "${brightness_path}.XXXXXX")
shell_stage=$(mktemp "${shell_path}.XXXXXX")
cleanup() {
    rm -f -- "${brightness_stage:-}" "${shell_stage:-}"
}
trap cleanup EXIT
cp -p -- "$brightness_path" "$brightness_stage"
cp -p -- "$shell_path" "$shell_stage"

replace_once "$brightness_stage" $'        readonly property bool isDdc: ddcInfo !== null\n' $'        readonly property bool isDdc: ddcInfo !== null\n        readonly property bool isInternalDisplay: /^(eDP|LVDS|DSI)/i.test(modelData.name)\n        readonly property bool isSoftwareDimming: !isDdc && !isAppleDisplay && !isInternalDisplay\n'
replace_once "$brightness_stage" $'            brightness = value;\n\n            if (isAppleDisplay)' $'            brightness = value;\n\n            if (isSoftwareDimming)\n                return;\n\n            if (isAppleDisplay)'
replace_once "$brightness_stage" $'        function initBrightness(): void {\n            if (isAppleDisplay)' $'        function initBrightness(): void {\n            if (isSoftwareDimming) {\n                brightness = 1;\n                return;\n            }\n\n            if (isAppleDisplay)'
replace_once "$shell_stage" $'    Lock {\n        id: lock\n' $'    BrightnessException {}\n\n    Lock {\n        id: lock\n'

cp -p -- "$brightness_path" "$brightness_backup"
cp -p -- "$shell_path" "$shell_backup"
mv -- "$brightness_stage" "$brightness_path"
brightness_stage=
mv -- "$shell_stage" "$shell_path"
shell_stage=
cp -- "$PROJECT_DIR/BrightnessException.qml" "$CONFIG_DIR/BrightnessException.qml"
cp -- "$PROJECT_DIR/BrightnessExceptionWindow.qml" "$CONFIG_DIR/BrightnessExceptionWindow.qml"
printf '{"project":"%s","version":1}\n' "$(basename -- "$PROJECT_DIR")" > "$MARKER"

printf 'Installed exception in %s\n' "$CONFIG_DIR"
printf 'Backups saved in %s\n' "$STATE_DIR"