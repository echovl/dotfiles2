return {
	{
		"nvim-telescope/telescope.nvim",
		version = "0.1.3",
		cmd = "Telescope",
		keys = {
			{ "<leader>pf", ":lua require('telescope.builtin').find_files()<CR>", mode = "n" },
			{ "<C-p>", ":lua require('telescope.builtin').git_files()<CR>", mode = "n" },
			{ "<leader>ps", ":lua require('telescope.builtin').live_grep()<CR>", mode = "n" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
}
