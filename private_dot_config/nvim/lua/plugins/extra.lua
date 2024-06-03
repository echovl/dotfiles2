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
		"numToStr/Comment.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
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
	-- {
	-- 	"zbirenbaum/copilot.lua",
	-- 	cmd = "Copilot",
	-- 	event = "InsertEnter",
	-- 	config = function(_, opts)
	-- 		require("copilot").setup(opts)
	-- 	end,
	-- 	opts = {
	-- 		suggestion = { enabled = true, auto_trigger = true, keymap = { accept = "<C-J>" } },
	-- 		filetypes = {
	-- 			markdown = true,
	-- 			help = true,
	-- 		},
	-- 	},
	-- },
}
