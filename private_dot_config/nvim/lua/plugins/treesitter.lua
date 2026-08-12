return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "main",
		event = { "BufReadPost", "BufNewFile" },
		-- opts = {
		-- 	ensure_installed = "all",
		-- 	ignore_install = { "comment", "verilog", "systemverilog", "ipkg" },
		-- 	sync_install = false,
		-- 	auto_install = true,
		-- 	highlight = {
		-- 		enable = true,
		-- 		disable = { "json" },
		-- 		additional_vim_regex_highlighting = false,
		-- 	},
		-- 	indent = {
		-- 		enable = true,
		-- 	},
		-- },
		config = function()
			local ts = require("nvim-treesitter")

			local parsers = {
				"bash",
				"css",
				"diff",
				"dtd",
				"ecma",
				"editorconfig",
				"fish",
				"git_config",
				"git_rebase",
				"gitattributes",
				"gitcommit",
				"gitignore",
				"hcl",
				"html",
				"html_tags",
				"javascript",
				"jsdoc",
				"json",
				"jsx",
				"latex",
				"lua",
				"make",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"regex",
				"scss",
				"toml",
				"tsx",
				"typescript",
				"typst",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
				"yang",
			}

			for _, parser in ipairs(parsers) do
				ts.install(parser)
			end

			-- Not every tree-sitter parser is the same as the file type detected
			-- So the patterns need to be registered more cleverly
			local patterns = {}
			for _, parser in ipairs(parsers) do
				local parser_patterns = vim.treesitter.language.get_filetypes(parser)
				for _, pp in pairs(parser_patterns) do
					table.insert(patterns, pp)
				end
			end

			vim.treesitter.language.register("groovy", "Jenkinsfile")
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

			vim.api.nvim_create_autocmd("FileType", {
				pattern = patterns,
				callback = function()
					vim.treesitter.start()
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			max_lines = 10,
		},
	},
}
