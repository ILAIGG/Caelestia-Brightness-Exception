# Caelestia software brightness fallback

This project adds a software dimmer for external monitors that do not expose
brightness control through DDC/CI. It determines the fallback from the
available brightness backend, not from the monitor brand or model, so it also
works when a monitor's connector name changes.

Monitors supported by DDC/CI or Apple Studio Display keep Caelestia's hardware
brightness control. Internal displays (eDP, LVDS, and DSI connectors) keep the
`brightnessctl` backend. The overlay ignores panel-reserved margins so it dims
the full display without changing Hyprland's usable area for application
windows.

## Install

```sh
./install.sh
caelestia shell --restart
```

The installer copies the packaged Caelestia shell into the user's
`~/.config/quickshell/caelestia` only when that directory does not already
exist. It saves the two files it changes under
`~/.local/state/caelestia-brightness-exception/` before editing them.
To update an existing installation, run `./update.sh`, then restart the
Caelestia shell.

## Uninstall

```sh
./uninstall.sh
caelestia shell --restart
```

Uninstall restores the saved files and removes the exception overlay. It keeps
the user configuration directory and all unrelated files intact.

The software dimmer darkens rendered pixels; it cannot change the monitor's
backlight or reproduce hardware dimming exactly.

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE).