#!/usr/bin/env python3
from pathlib import Path


CONFIG_DIR = Path.home() / ".config/quickshell/caelestia"
STATE_DIR = Path.home() / ".local/state/caelestia-brightness-exception"
MARKER = CONFIG_DIR / ".brightness-exception.json"


def main() -> None:
    if not MARKER.exists():
        raise SystemExit("Brightness exception is not installed.")

    brightness_backup = STATE_DIR / "Brightness.qml.backup"
    shell_backup = STATE_DIR / "shell.qml.backup"
    if not brightness_backup.is_file() or not shell_backup.is_file():
        raise SystemExit(f"Cannot restore configuration; backups are missing from {STATE_DIR}")

    (CONFIG_DIR / "services/Brightness.qml").write_bytes(brightness_backup.read_bytes())
    (CONFIG_DIR / "shell.qml").write_bytes(shell_backup.read_bytes())
    (CONFIG_DIR / "BrightnessException.qml").unlink(missing_ok=True)
    (CONFIG_DIR / "BrightnessExceptionWindow.qml").unlink(missing_ok=True)
    MARKER.unlink()
    brightness_backup.unlink()
    shell_backup.unlink()
    STATE_DIR.rmdir()
    print(f"Restored the original Caelestia files in {CONFIG_DIR}")


if __name__ == "__main__":
    main()