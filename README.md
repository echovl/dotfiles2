# dotfiles

Hyprland on CachyOS: a Quickshell bar, dunst, rofi, alacritty, Neovim and a
greetd/tuigreet login screen, all colored by [tinty](https://github.com/tinted-theming/tinty).
Managed with [chezmoi](https://chezmoi.io).

## New machine

On a fresh CachyOS install, as your user:

```sh
sudo pacman -S --needed chezmoi
chezmoi init --apply echovl/dotfiles2
reboot
```

Use `chezmoi init --apply --ssh echovl/dotfiles2` instead if the machine has
an SSH key on GitHub, so you can push from it.

`chezmoi apply` asks for your password twice, once with sudo and once with
polkit, and does this in order:

1. `run_onchange_before_install-packages`: installs whatever is missing from
   [`.chezmoidata/packages.yaml`](.chezmoidata/packages.yaml), with pacman and
   then paru for the AUR, then turns on the services listed there (Docker,
   Tailscale, Mullvad, tuned) and adds you to the `docker` and `nordvpn`
   groups. If pacman asks to remove power-profiles-daemon, answer y: tuned-ppd
   replaces it.
2. Writes the dotfiles, the wallpaper and the tmux plugins
   ([`.chezmoiexternal.toml`](.chezmoiexternal.toml)).
3. `run_onchange_after_install-greeter`: installs the login screen files from
   [`system/`](system) and makes greetd the login manager from the next boot.
4. `run_onchange_after_setup-tinty`: installs tinty's schemes and theme repos,
   then applies the default scheme (Catppuccin Mocha). That writes every
   generated color file.

The first time you open Neovim, it installs its plugins and language servers.

## Not included

Hardware-specific setup stays out of the repo. tuned is installed, but the
Framework 13's power tuning (tuned profile and SSD/Wi-Fi tweaks) has to be
redone by hand. Its screen
scale is a Hyprland rule matched by panel model (`hyprland.lua`), so any other
screen gets Hyprland's automatic scale.

## Day to day

- **Change the theme:** `tinty apply base16-dracula`. Everything follows,
  including open Neovim windows and the login screen.
- **Add a package:** put it in `.chezmoidata/packages.yaml`; the next
  `chezmoi apply` installs it.
- **Change the login screen:** edit the files in `system/`, then
  `chezmoi apply` installs them. Don't edit them in `/etc`.
- **Generated files** (`colors.toml`, `colors.rasi`, `colors.lua`, the dunst
  and yazi colors) come from tinty hooks and are not tracked.
