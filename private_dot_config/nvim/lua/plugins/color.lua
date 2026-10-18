return {
	-- { "dracula/vim",              lazy = true },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },
	-- { "ellisonleao/gruvbox.nvim", lazy = true },
	{ "sainnhe/gruvbox-material", lazy = true },
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
