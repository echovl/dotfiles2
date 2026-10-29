# bar

A minimal Quickshell bar in the style of Omarchy's: workspaces and window
title, now playing, date with a calendar, the weather (click its place to pick another) and pending updates, and tray, system stats, Bluetooth,
Wi-Fi, sound, brightness, battery and notification icons with popups, a
caffeine toggle that keeps the screen awake, plus a volume/brightness overlay.
It is also the notification daemon, in place of dunst or mako.

Run with `qs -c bar`, stop with `qs kill -c bar`.

## Dependencies

Arch package names.

**Required**

| Package | For |
| --- | --- |
| `quickshell` (0.3+) | runs the bar; the official package, not `noctalia-qs` |
| `hyprland` | workspaces, window title, `hyprctl` |
| `ttf-jetbrains-mono-nerd` | font and icons |
| `papirus-icon-theme` | app icons on notifications and in the tray (`//@ pragma IconTheme Papirus-Dark` in `shell.qml`; restart the bar after changing it) |
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
| `curl` | weather: location from GeoJS (by IP) unless you pick one in its popup (Open-Meteo's place search), forecast from Open-Meteo |
| `hypridle` | what the caffeine toggle holds off (any idle daemon that honors Wayland idle inhibitors) |
| `pacman-contrib` (`checkupdates`) | pending updates; `paru` adds AUR ones and runs the update |
| `alacritty` | the terminal the update runs in |
| `wl-clipboard` | copying a verification code from a notification |

The now-playing widget works with any player that supports MPRIS (Spotify,
browsers, mpv with mpv-mpris).

Tray icons come from apps that support StatusNotifierItem; the bar provides
the tray itself.

## Notifications

The bar owns `org.freedesktop.Notifications`, so no other notification daemon
may run. Cards appear in the top-right corner of the focused screen, below the
bar, and stay on that screen until they are all gone:

- Cards from one app (or, for a browser, one site) stack into a deck: the
  newest in front, two more peeking out below. Pointing at a deck opens it,
  shows the whole body and holds every card's time; cards that arrive
  meanwhile wait until the pointer leaves (at most 30 seconds).
- A card shows the sender's picture with the app's icon as a badge, its title
  and body (bold, italic, underline and links; never remote images), a
  progress bar for the `value` hint, and a button bar: the sender's actions,
  **Copy code** for a verification code in the text, and **Reply** for apps
  that support inline replies (Telegram, KDE apps).
- Left-click runs the sender's default action and focuses its window;
  right- or middle-click, or the close mark, dismisses it.
- Low notifications stay 5 seconds, normal ones 8, or the sender's own
  timeout; critical ones stay until dismissed.
- A notification with the same `x-dunst-stack-tag` (or
  `x-canonical-private-synchronous`) as an open one from the same app
  replaces it in place, as in dunst, as does one sent with a `replaces_id`.
- When its card times out a notification stays in the bell's popup, actions
  and all, until it is dismissed there or its app closes it. One you clicked,
  ran an action of or replied to stays there too once it closes, without its
  actions (a click focuses the sender's window), until you dismiss it or
  clear the popup; transient ones don't. The popup holds the newest 50.
  Right-click the bell for Do Not Disturb: notifications go straight to the
  popup (critical ones still show), and a dot on the bell marks the ones you
  haven't seen. Do Not Disturb is kept across restarts.

For keybindings and scripts, in place of `dunstctl`:

```sh
qs -c bar ipc call notifications dismiss      # the newest card
qs -c bar ipc call notifications dismissAll   # every card on screen
qs -c bar ipc call notifications clear        # every notification, popup too
qs -c bar ipc call notifications invoke       # click the newest card
qs -c bar ipc call notifications restore      # bring the newest one back on screen
qs -c bar ipc call notifications toggleDnd    # or setDnd true|false
qs -c bar ipc prop get notifications dnd      # also: count
```

Replacing dunst: take it out of Hyprland's autostart and stop D-Bus from
starting it when something notifies before the bar is up:

```sh
systemctl --user mask dunst.service
```

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
windows (they animate themselves):

```lua
hl.layer_rule({ match = { namespace = "^qs-bar$" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "^(qs-bar|qs-popup|qs-osd|qs-notifications)$" }, no_anim = true, animation = "none" })
```
