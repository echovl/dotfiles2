return {
	-- { "dracula/vim",              lazy = true },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },
	-- { "ellisonleao/gruvbox.nvim", lazy = true },
	{ "sainnhe/gruvbox-material", lazy = true },
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
}
