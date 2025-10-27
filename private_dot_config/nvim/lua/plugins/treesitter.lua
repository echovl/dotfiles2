return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		cmd = { "TSUpdateSync" },
		branch = "master",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = "all",
			ignore_install = { "comment", "verilog", "systemverilog", "ipkg" },
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
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			max_lines = 10,
		},
	},
}
