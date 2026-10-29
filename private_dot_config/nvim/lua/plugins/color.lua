return {
	-- Native ports echovl/theme.lua uses for tinty schemes whose palette they
	-- match exactly; lazy, loaded by the first :colorscheme that needs them.
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },
	{ "sainnhe/gruvbox-material", lazy = true },
	{ "folke/tokyonight.nvim", lazy = true },
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	{ "Mofiqul/dracula.nvim", lazy = true },
	{ "rebelot/kanagawa.nvim", lazy = true },
	{ "sainnhe/everforest", lazy = true },
	{ "gbprod/nord.nvim", lazy = true },
	{ "kepano/flexoki-neovim", name = "flexoki", lazy = true },
	{ "eldritch-theme/eldritch.nvim", lazy = true },
	{ "tiagovla/tokyodark.nvim", lazy = true },
	{
		"vague-theme/vague.nvim",
		lazy = false,
		priority = 1000,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		opts = {
			flavour = "mocha",
			no_italic = true,
			no_bold = true,
			integrations = {
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				treesitter = true,
				notify = false,
				mini = {
					enabled = true,
					indentscope_color = "",
				},
			},
		},
	},
	-- { "navarasu/onedark.nvim",    lazy = true }
	{
		-- Every tinty scheme without a native port above; see echovl/theme.lua.
		"tinted-theming/tinted-nvim",
		lazy = true,
		opts = {
			apply_scheme_on_startup = false, -- echovl.theme picks the scheme
			styles = { comments = { italic = false } }, -- like catppuccin's no_italic
		},
	},
}
