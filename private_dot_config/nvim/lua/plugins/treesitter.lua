return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		cmd = { "TSUpdateSync" },
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = "all",
			ignore_install = { "comment" },
			sync_install = false,
			auto_install = true,
			highlight = {
				enable = true,
				disable = { "json" },
				additional_vim_regex_highlighting = false,
			},
			indent = {
				enable = true,
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
}
