return {
	{
		"Vimjas/vim-python-pep8-indent",
		event = { "BufReadPost", "BufNewFile" },
	},
	{
		"NvChad/nvim-colorizer.lua",
		lazy = false,
		opts = {},
	},
	{
		"tpope/vim-sleuth",
		lazy = false,
	},
	{
		"tpope/vim-fugitive",
		lazy = false,
	},
	{
		"supermaven-inc/supermaven-nvim",
		event = "InsertEnter",
		config = function(_, opts)
			require("supermaven-nvim").setup(opts)
		end,
		opts = {
			keymaps = {
				accept_suggestion = "<C-j>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-w>",
			},
			disable_keymaps = false,
		},
	},
}
