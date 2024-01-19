return {
	{
		"kyazdani42/nvim-tree.lua",
		dependencies = {
			"kyazdani42/nvim-web-devicons",
		},
		cmd = "NvimTreeToggle",
		keys = {
			{ "<leader>tr", "<cmd>NvimTreeToggle<CR>", mode = "n" },
		},
		deactivate = function()
			vim.cmd([[NvimTreeClose]])
		end,
		init = function()
			if vim.fn.argc() == 1 then
				local stat = vim.loop.fs_stat(vim.fn.argv(0))
				if stat and stat.type == "directory" then
					require("nvim-tree")
				end
			end
		end,
		opts = {},
	},
}
