#!/usr/bin/env python3
import json
import shutil
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent
CONFIG_DIR = Path.home() / ".config/quickshell/caelestia"
SYSTEM_CONFIG_DIR = Path("/etc/xdg/quickshell/caelestia")
STATE_DIR = Path.home() / ".local/state/caelestia-brightness-exception"
MARKER = CONFIG_DIR / ".brightness-exception.json"


def replace_once(text: str, old: str, new: str, path: Path) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one patch anchor in {path}, found {count}")
    return text.replace(old, new, 1)


def main() -> None:
    if not SYSTEM_CONFIG_DIR.is_dir():
        raise SystemExit(f"Caelestia shell not found: {SYSTEM_CONFIG_DIR}")

    if MARKER.exists():
        print("Brightness exception is already installed.")
        return

    if not CONFIG_DIR.exists():
        shutil.copytree(SYSTEM_CONFIG_DIR, CONFIG_DIR, symlinks=True)

    brightness_path = CONFIG_DIR / "services/Brightness.qml"
    shell_path = CONFIG_DIR / "shell.qml"
    if not brightness_path.is_file() or not shell_path.is_file():
        raise SystemExit("The local Caelestia configuration is missing required files.")

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    brightness_backup = STATE_DIR / "Brightness.qml.backup"
    shell_backup = STATE_DIR / "shell.qml.backup"
    if brightness_backup.exists() or shell_backup.exists():
        raise SystemExit(f"Existing backup found in {STATE_DIR}; inspect it before installing.")

    brightness = brightness_path.read_text()
    brightness = replace_once(
        brightness,
        "        readonly property bool isDdc: ddcInfo !== null\n",
        "        readonly property bool isDdc: ddcInfo !== null\n"
        "        readonly property bool isInternalDisplay: /^(eDP|LVDS|DSI)/i.test(modelData.name)\n"
        "        readonly property bool isSoftwareDimming: !isDdc && !isAppleDisplay && !isInternalDisplay\n",
        brightness_path,
    )
    brightness = replace_once(
        brightness,
        "            brightness = value;\n\n            if (isAppleDisplay)",
        "            brightness = value;\n\n            if (isSoftwareDimming)\n                return;\n\n            if (isAppleDisplay)",
        brightness_path,
    )
    brightness = replace_once(
        brightness,
        "        function initBrightness(): void {\n            if (isAppleDisplay)",
        "        function initBrightness(): void {\n            if (isSoftwareDimming) {\n                brightness = 1;\n                return;\n            }\n\n            if (isAppleDisplay)",
        brightness_path,
    )

    shell = shell_path.read_text()
    shell = replace_once(
        shell,
        "    Lock {\n        id: lock\n",
        "    BrightnessException {}\n\n    Lock {\n        id: lock\n",
        shell_path,
    )

    shutil.copy2(brightness_path, brightness_backup)
    shutil.copy2(shell_path, shell_backup)
    brightness_path.write_text(brightness)
    shell_path.write_text(shell)
    shutil.copy2(PROJECT_DIR / "BrightnessException.qml", CONFIG_DIR / "BrightnessException.qml")
    shutil.copy2(PROJECT_DIR / "BrightnessExceptionWindow.qml", CONFIG_DIR / "BrightnessExceptionWindow.qml")
    MARKER.write_text(json.dumps({"project": PROJECT_DIR.name, "version": 1}) + "\n")
    print(f"Installed exception in {CONFIG_DIR}")
    print(f"Backups saved in {STATE_DIR}")


if __name__ == "__main__":
    main()