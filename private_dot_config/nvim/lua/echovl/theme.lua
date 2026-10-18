-- Follow tinty: load the colorscheme for the scheme `tinty apply` last set, and
-- switch live when it changes. Schemes with a native Neovim port use it, since
-- those have far more detailed highlights; everything else goes through
-- tinted-nvim's bundled base16/base24 palettes.
local M = {}

M.file = vim.fn.expand("~/.local/share/tinted-theming/tinty/current_scheme")
M.fallback = "base16-catppuccin-mocha"

-- tinty scheme name pattern -> loader for the native port; captures are
-- passed to the loader.
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
		if captures[1] then
			entry[2](unpack(captures))
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
	-- The last hook in tinty's config.toml sends SIGUSR1 to every nvim after
	-- each apply, once current_scheme already holds the new name.
	vim.api.nvim_create_autocmd("Signal", { pattern = "SIGUSR1", callback = refresh })
	-- Catches a scheme change that came without the signal.
	vim.api.nvim_create_autocmd("FocusGained", { callback = refresh })
end

return M
