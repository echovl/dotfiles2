return {
	{
		"benlubas/molten-nvim",
		version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
		build = ":UpdateRemotePlugins",
		init = function()
			-- this is an example, not a default. Please see the readme for more configuration options
			vim.g.molten_output_win_max_height = 12
			vim.g.molten_auto_open_output = false

			-- Output as virtual text. Allows outputs to always be shown, works with images, but can
			-- be buggy with longer images
			vim.g.molten_virt_text_output = true

			-- this will make it so the output shows up below the \`\`\` cell delimiter
			vim.g.molten_virt_lines_off_by_1 = true
		end,
	},
}
