require("echovl.set")
require("echovl.keymap")
require("echovl.cmds")
require("echovl.lazy")

vim.g.gruvbox_material_background = "hard"
vim.cmd("colorscheme catppuccin")

vim.cmd("highlight LineNr guibg=NONE")
vim.cmd("highlight SignColumn guibg=NONE")

vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
