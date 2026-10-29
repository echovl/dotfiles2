-- Follow tinty: load the colorscheme for the scheme `tinty apply` last set, and
-- switch live when it changes. Schemes with a native Neovim port drawn in the
-- scheme's own palette use it, since those have far more detailed highlights;
-- everything else goes through tinted-nvim's bundled base16/base24 palettes.
local M = {}

M.file = vim.fn.expand("~/.local/share/tinted-theming/tinty/current_scheme")
M.fallback = "base16-catppuccin-mocha"

-- tinty scheme name pattern -> loader for the native port; captures are
-- passed to the loader. A loader returns false for a variant its port draws
-- differently, which then goes through tinted-nvim like any other scheme.
local native = {
	{
		"^base%d%d%-catppuccin%-(%a+)$",
		function(flavour)
			vim.cmd.colorscheme("catppuccin-" .. flavour)
		end,
	},
	{
		"^base%d%d%-rose%-pine%-?(%a*)$",
		function(variant)
			vim.cmd.colorscheme(variant == "" and "rose-pine-main" or "rose-pine-" .. variant)
		end,
	},
	{
		"^base%d%d%-gruvbox%-material%-(%a+)%-(%a+)$",
		function(background, contrast)
			vim.o.background = background
			vim.g.gruvbox_material_background = contrast
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},
	{
		-- tokyonight's "day" isn't tinty's Tokyo Night Light; terminal-* don't match.
		"^base%d%d%-tokyo%-night%-(%a+)$",
		function(variant)
			local style = ({ dark = "night", storm = "storm", moon = "moon" })[variant]
			if not style then
				return false
			end
			vim.cmd.colorscheme("tokyonight-" .. style)
		end,
	},
	{
		-- dark/light, then hard/medium/soft (none: medium); not dark-pale.
		"^base%d%d%-gruvbox%-(%a+)%-?(%a*)$",
		function(background, contrast)
			contrast = ({ [""] = "", medium = "", hard = "hard", soft = "soft" })[contrast]
			if not contrast or (background ~= "dark" and background ~= "light") then
				return false
			end
			vim.o.background = background
			require("gruvbox").setup({ contrast = contrast })
			vim.cmd.colorscheme("gruvbox")
		end,
	},
	{
		"^base%d%d%-dracula$",
		function()
			vim.cmd.colorscheme("dracula")
		end,
	},
	{
		-- Plain "kanagawa" is its wave theme.
		"^base%d%d%-kanagawa%-?(%a*)$",
		function(theme)
			if theme ~= "" and theme ~= "dragon" then
				return false
			end
			vim.cmd.colorscheme("kanagawa-" .. (theme == "" and "wave" or theme))
		end,
	},
	{
		-- Plain "everforest" is the dark, medium one.
		"^base%d%d%-everforest%-?(%a*)%-?(%a*)$",
		function(background, contrast)
			if background == "" then
				background, contrast = "dark", "medium"
			end
			if (background ~= "dark" and background ~= "light") or not ({ hard = 1, medium = 1, soft = 1 })[contrast] then
				return false
			end
			vim.o.background = background
			vim.g.everforest_background = contrast
			vim.cmd.colorscheme("everforest")
		end,
	},
	{
		-- Not nord-light: nord.nvim is dark only.
		"^base%d%d%-nord$",
		function()
			vim.cmd.colorscheme("nord")
		end,
	},
	{
		"^base%d%d%-flexoki%-(%a+)$",
		function(variant)
			if variant ~= "dark" and variant ~= "light" then
				return false
			end
			vim.cmd.colorscheme("flexoki-" .. variant)
		end,
	},
	{
		-- Neovim's own default colorscheme.
		"^base%d%d%-neovim%-(%a+)$",
		function(background)
			if background ~= "dark" and background ~= "light" then
				return false
			end
			vim.o.background = background
			vim.cmd.colorscheme("default")
		end,
	},
	{
		"^base%d%d%-eldritch$",
		function()
			vim.cmd.colorscheme("eldritch")
		end,
	},
	{
		-- The terminal variant has the same palette.
		"^base%d%d%-tokyodark%-?(%a*)$",
		function(variant)
			if variant ~= "" and variant ~= "terminal" then
				return false
			end
			vim.cmd.colorscheme("tokyodark")
		end,
	},
}

-- The scheme name tinty wrote, or nil while the file is missing or mid-write.
local function read_scheme()
	local ok, lines = pcall(vim.fn.readfile, M.file)
	local name = ok and lines[1] and vim.trim(lines[1]) or ""
	return name ~= "" and name or nil
end

-- lualine's "auto" finds the native ports' own lualine themes; tinted-nvim
-- ships a "tinted" one instead.
local function set_lualine_theme(theme)
	local ok, lualine = pcall(require, "lualine")
	if not ok then
		return
	end
	local config = lualine.get_config()
	if config.options.theme ~= theme then
		config.options.theme = theme
		lualine.setup(config)
	end
end

function M.apply(name)
	for _, entry in ipairs(native) do
		local captures = { name:match(entry[1]) }
		if captures[1] and entry[2](unpack(captures)) ~= false then
			set_lualine_theme("auto")
			M.current = name
			return
		end
	end

	local ok, err = pcall(function()
		require("tinted-nvim").load(name)
	end)
	if not ok then
		vim.notify(("tinty scheme %s: %s"):format(name, err), vim.log.levels.WARN)
		if name ~= M.fallback then
			M.apply(M.fallback)
		end
		M.current = name -- don't retry (and warn again) until tinty switches
		return
	end
	set_lualine_theme("tinted")
	M.current = name
end

local function refresh()
	local name = read_scheme()
	if name and name ~= M.current then
		M.apply(name)
	end
end

function M.setup()
	M.apply(read_scheme() or M.fallback)
	-- Both are nested: :colorscheme inside them must fire ColorSchemePre, where
	-- lazy.nvim loads a lazy theme plugin not loaded yet (else E185), and
	-- ColorScheme, which lualine and the transparency overrides listen on.
	-- The last hook in tinty's config.toml sends SIGUSR1 to every nvim after
	-- each apply, once current_scheme already holds the new name.
	vim.api.nvim_create_autocmd("Signal", { pattern = "SIGUSR1", nested = true, callback = refresh })
	-- Catches a scheme change that came without the signal.
	vim.api.nvim_create_autocmd("FocusGained", { nested = true, callback = refresh })
end

return M
