vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
-- vim.keymap.set("n", "<C-d>", "<C-d>")
-- vim.keymap.set("n", "<C-u>", "<C-u>")
-- vim.keymap.set("n", "n", "nzzzv")
-- vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "<leader>j", ":cnext<CR>")
vim.keymap.set("n", "<leader>k", ":cprev<CR>")
vim.keymap.set("n", "<C-j>", ":lnext<CR>")
vim.keymap.set("n", "<C-k", ":lprev<CR>")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Molten keymaps
vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>", { silent = true, desc = "Initialize the plugin" })
vim.keymap.set("n", "<leader>me", ":MoltenEvaluateOperator<CR>", { silent = true, desc = "run operator selection" })
vim.keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>", { silent = true, desc = "evaluate line" })
vim.keymap.set("n", "<leader>rr", ":MoltenReevaluateCell<CR>", { silent = true, desc = "re-evaluate cell" })
vim.keymap.set(
	"v",
	"<localleader>r",
	":<C-u>MoltenEvaluateVisual<CR>gv",
	{ silent = true, desc = "evaluate visual selection" }
)
vim.keymap.set(
	"n",
	"<leader>os",
	":noautocmd MoltenEnterOutput<CR>",
	{ desc = "open output window", silent = true }
)
vim.keymap.set("n", "<leader>oh", ":MoltenHideOutput<CR>", { desc = "close output window", silent = true })
