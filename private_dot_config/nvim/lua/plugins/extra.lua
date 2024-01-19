return {
	{
		"Vimjas/vim-python-pep8-indent",
		event = { "BufReadPost", "BufNewFile" },
	},
	-- {
	-- 	"NvChad/nvim-colorizer.lua",
	-- 	lazy = false,
	-- 	opts = {},
	-- },
	{
		"tpope/vim-sleuth",
		lazy = false,
	},
	{
		"numToStr/Comment.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},
	{
		"tpope/vim-fugitive",
		lazy = false,
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function(_, opts)
			require("copilot").setup(opts)
		end,
		opts = {
			suggestion = { enabled = true, auto_trigger = true, keymap = { accept = "<C-J>" } },
			filetypes = {
				markdown = true,
				help = true,
			},
		},
	},
}
