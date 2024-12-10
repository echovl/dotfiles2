-- Provide a command to create a blank new Python notebook
-- note: the metadata is needed for Jupytext to understand how to parse the notebook.
-- if you use another language than Python, you should change it in the template.
local default_notebook = [[
	{
		"cells": [],
		"metadata": {
			"kernelspec": {
				"display_name": "R",
				"language": "R",
				"name": "ir"
			},
			"language_info": {
				"codemirror_mode": "r",
				"file_extension": ".r",
				"mimetype": "text/x-r-source",
				"name": "R",
				"pygments_lexer": "r",
				"version": "4.4.1"
			}
		},
		"nbformat": 4,
		"nbformat_minor": 5
	}
]]

local function new_notebook(filename)
	local path = filename .. ".ipynb"
	local file = io.open(path, "w")
	if file then
		file:write(default_notebook)
		file:close()
		vim.cmd("edit " .. path)
	else
		print("Error: Could not open new notebook file for writing.")
	end
end

vim.api.nvim_create_user_command("NewRNotebook", function(opts)
	new_notebook(opts.args)
end, {
	nargs = 1,
	complete = "file",
})
