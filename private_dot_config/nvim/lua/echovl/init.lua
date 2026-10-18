require("echovl.set")
require("echovl.keymap")
require("echovl.cmds")
require("echovl.lazy")

vim.g.gruvbox_material_background = "hard"

-- Keep these transparent under every colorscheme, including ones tinty
-- switches to later.
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.cmd("highlight LineNr guibg=NONE")
		vim.cmd("highlight SignColumn guibg=NONE")
	end,
})
require("echovl.theme").setup()

-- Python plugins use this virtualenv (with pynvim) when it exists.
local python = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
if vim.fn.executable(python) == 1 then
	vim.g.python3_host_prog = python
end
