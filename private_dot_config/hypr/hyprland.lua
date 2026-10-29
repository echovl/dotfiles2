---@module 'hl'

-- See https://wiki.hyprland.org/Configuring/Monitors/

-- Any screen without its own rule: preferred mode, scale picked from its DPI.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-- The Framework 13's panel, matched by model (`hyprctl monitors` description)
-- rather than eDP-1, so another laptop's screen gets the rule above.
hl.monitor({
	output = "desc:BOE NE135A1M-NY1",
	mode = "2880x1920@120.00Hz",
	position = "auto",
	-- scale = 1.667,
	scale = 1.875,
})

hl.monitor({
	output = "DP-4",
	mode = "3840x2160@60.00Hz",
	position = "auto",
	scale = 1.67,
})

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more

-- Cursor size.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Wayland backend.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", 1)

-- No window decorations.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", 1)

-- Scale gtk apps using xwayland.
hl.env("GDK_SCALE", "2")

hl.config({
	input = {
		kb_layout = "us",
		kb_options = "ctrl:nocaps",
		follow_mouse = 0,
		-- accel_profile = flat
		touchpad = {
			natural_scroll = false,
			scroll_factor = 0.3,
		},
		sensitivity = 0,
		-- -1.0 - 1.0, 0 means no modification.
	},
})

hl.config({
	general = {
		-- See https://wiki.hyprland.org/Configuring/Variables/ for more
		gaps_in = 5,
		gaps_out = 15,
		border_size = 2,
		col = {
			active_border = "0xff89b4fa",
			inactive_border = "0xff444444",
		},
		layout = "master",
		-- column_width = 0.7,
		-- Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
		-- allow_tearing = false
	},
})

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

hl.config({
	decoration = {
		-- See https://wiki.hyprland.org/Configuring/Variables/ for more
		rounding = 2,
		shadow = {
			enabled = false,
			range = 2,
			render_power = 4,
		},
		blur = {
			enabled = false,
			new_optimizations = true,
			size = 12,
			-- noise = 0.01,
			passes = 1,
		},
	},
})

hl.config({
	animations = {
		enabled = true,
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })

hl.config({
	dwindle = {
		-- See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
		-- pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
		preserve_split = true,
		-- you probably want this
	},
})

hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		-- vrr = true,
		-- vfr = true
	},
})

-- windowrule = opacity 0.98 override 0.85 override,^(foot|Alacritty)$
-- windowrule = opacity 0.98 override 0.85 override,^(rofi)$

hl.window_rule({
	name = "pavucontrol-float",
	match = {
		class = "org.pulseaudio.pavucontrol",
	},
	size = "50% 50%",
	float = true,
})

hl.window_rule({
	name = "xdg-file-opener-float",
	match = {
		title = "All Files",
		class = "xdg-desktop-portal-gtk",
	},
	float = true,
	max_size = { "monitor_w * 0.5", "monitor_h * 0.5" },
	center = true,
})

hl.window_rule({
	name = "helium-signin-float",
	match = {
		class = "helium",
		title = "Sign in.*",
	},
	float = true,
})

hl.window_rule({
	name = "rabby-popup-float",
	match = {
		class = "chrome-acmacodkjbdgmoleebolmdjonilkdbch-Default",
	},
	float = true,
})

-- Alacritty ignores its scrolling.multiplier while an app has mouse reporting
-- on (discordo, nvim, ...), so scale its input here instead. 3.0 matches
-- Ghostty: global touchpad factor 0.3 x Ghostty's built-in x10, and Ghostty's
-- default 3 rows per wheel notch. Pairs with scrolling.multiplier = 1 in
-- alacritty.toml so shell scrollback lands on the same speed.
hl.window_rule({
	name = "alacritty-scroll-opacity",
	match = {
		class = "Alacritty",
	},
	scroll_touchpad = 1.5,
	-- scroll_mouse = 3.0,
	opacity = "0.98 override 0.94 override",
})

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more

local mainMod = "SUPER"

-- terminal
hl.bind(mainMod .. " + " .. "RETURN", hl.dsp.exec_cmd("alacritty"))

-- app launcher: cachy-cast (global shortcut handled inside `qs -c cachy-cast`)
hl.bind(mainMod .. " + " .. "d", hl.dsp.global("cachy-cast:toggle"))

-- screenshot
hl.bind(mainMod .. " + " .. "P", hl.dsp.exec_cmd("hyprshot -m region -s --clipboard-only"))

-- media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("light -A 5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("light -U 5"), { locked = true, repeating = true })

-- lock screen
hl.bind(mainMod .. " + " .. "CTRL" .. " + " .. "l", hl.dsp.exec_cmd("loginctl lock-session"))

-- close window
hl.bind(mainMod .. " + " .. "Q", hl.dsp.window.close())

-- TODO: remap to bspwm equivalents
hl.bind(mainMod .. " + " .. "M", hl.dsp.exit())
hl.bind(mainMod .. " + " .. "V", hl.dsp.window.float())
-- hl.bind(mainMod .. " + " .. "P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + " .. "F", hl.dsp.window.fullscreen())

-- Move focus with mainMod + hjkl keys
hl.bind(mainMod .. " + " .. "h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + " .. "l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + " .. "k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + " .. "j", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
hl.bind(mainMod .. " + " .. 1, hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + " .. 2, hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + " .. 3, hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + " .. 4, hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + " .. 5, hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + " .. 6, hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + " .. 7, hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + " .. 8, hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + " .. 9, hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + " .. 0, hl.dsp.focus({ workspace = 10 }))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 1, hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 2, hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 3, hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 4, hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 5, hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 6, hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 7, hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 8, hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 9, hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 0, hl.dsp.window.move({ workspace = 10 }))

-- Swap active window to an adjacent window with mainMod + SHIFT + hjkl keys
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "h", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "l", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "k", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "j", hl.dsp.window.swap({ direction = "down" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + " .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + " .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Quickshell bar (~/.config/quickshell/bar): Hyprland blurs behind its glassy
-- background, and leaves animating its windows (the notification cards too)
-- to the bar, which animates them itself.
hl.layer_rule({ match = { namespace = "^qs-bar$" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "^(qs-bar|qs-popup|qs-osd|qs-notifications)$" }, no_anim = true, animation = "none" })

-- Autostart
hl.on("hyprland.start", function()
	-- Also the notification daemon (in place of dunst).
	hl.exec_cmd("qs -c bar")
	hl.exec_cmd("qs -c cachy-cast")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")
	hl.exec_cmd("swaybg -i ~/Pictures/wallhaven-6lykzx.png")
	hl.exec_cmd("hypridle")
end)

-- Exec (run every reload)
hl.on("config.reloaded", function() end)

-- Window border colors from the applied tinty scheme, written by
-- ~/.config/tinted-theming/tinty/hooks/hyprland-colors.sh. They override the
-- colors above, which stay in use while the file is missing.
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/colors.lua")
