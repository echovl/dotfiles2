# bar

A minimal Quickshell bar in the style of Omarchy's: workspaces and window
title, now playing, date with a calendar, the weather and pending updates, and tray, system stats, Bluetooth,
Wi-Fi, sound, brightness, battery and notification icons with popups, plus a
volume/brightness overlay.

Run with `qs -c bar`, stop with `qs kill -c bar`.

## Dependencies

Arch package names.

**Required**

| Package | For |
| --- | --- |
| `quickshell` (0.3+) | runs the bar; the official package, not `noctalia-qs` |
| `hyprland` | workspaces, window title, `hyprctl` |
| `ttf-jetbrains-mono-nerd` | font and icons |
| `bash`, `gawk`, `procps-ng` | helper scripts in `scripts/` |

**Per widget**

| Package | For |
| --- | --- |
| `pipewire` | sound popup and volume overlay |
| `bluez` | Bluetooth popup |
| `networkmanager` | Wi-Fi popup |
| `iproute2`, `iputils` | IP, gateway and ping in the Wi-Fi popup |
| `upower` | battery icon and popup |
| `power-profiles-daemon` or `tuned-ppd` | power profile buttons |
| `systemd` (logind, `busctl`) | setting brightness without root |
| `imagemagick`, `swaybg` | text color of the clear bar, read from the wallpaper |
| `curl` | weather: location from wttr.in (by IP), forecast from Open-Meteo |
| `dunst` | notifications popup and Do Not Disturb |
| `pacman-contrib` (`checkupdates`) | pending updates; `paru` adds AUR ones and runs the update |
| `alacritty` | the terminal the update runs in |

The now-playing widget works with any player that supports MPRIS (Spotify,
browsers, mpv with mpv-mpris).

Tray icons come from apps that support StatusNotifierItem; the bar provides
the tray itself.

## Colors (tinty)

The bar takes its colors from the applied [tinty](https://github.com/tinted-theming/tinty)
scheme (`base00` background, `base05` text, `base0D` accent, `base08` urgent),
and falls back to Omarchy's Tokyo Night without one. `scripts/tinty-hook.sh`
writes the palette to `~/.local/state/quickshell/bar/colors.json`, which the
bar watches, so `tinty apply` recolors it without a restart. Register the hook
in `~/.config/tinted-theming/tinty/config.toml`:

```toml
hooks = ["$HOME/.config/quickshell/bar/scripts/tinty-hook.sh"]
```

## Hyprland (optional)

So the glassy background is blurred and Hyprland doesn't animate the bar's
windows (they fade themselves):

```lua
hl.layer_rule({ match = { namespace = "^qs-bar$" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "^(qs-bar|qs-popup|qs-osd)$" }, no_anim = true, animation = "none" })
```
