#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_DIR=${XDG_CONFIG_HOME:-"$HOME/.config"}/quickshell/caelestia

if [[ -e $CONFIG_DIR/.brightness-exception.json ]]; then
    "$PROJECT_DIR/uninstall.sh"
fi

"$PROJECT_DIR/install.sh"
printf 'Restart Caelestia to apply the update: caelestia shell --restart\n'