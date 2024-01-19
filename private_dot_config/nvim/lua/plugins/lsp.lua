local check_back_space = function()
	local col = vim.fn.col(".") - 1
	if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
		return true
	else
		return false
	end
end

return {
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		opts = {
			servers = {
				gopls = {},
				-- tsserver = {},
				rust_analyzer = {},
				jsonls = {},
				html = {},
				emmet_language_server = {},
				solidity_ls_nomicfoundation = {},
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
						},
					},
				},
				pylsp = {
					settings = {
						pylsp = {
							plugins = {
								rope_autoimport = {
									enabled = false,
								},
								pycodestyle = {
									enabled = false,
								},
								mypy = {
									enabled = false,
									live_mode = true,
								},
							},
						},
					},
				},
			},
		},
		config = function(_, opts)
			-- keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local keymap_opts = { buffer = args.buf, remap = false }

					-- disable semantic tokens highlight
					client.server_capabilities.semanticTokensProvider = nil

					vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, keymap_opts)
					vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, keymap_opts)
					vim.keymap.set("n", "]d", vim.diagnostic.goto_next, keymap_opts)

					vim.keymap.set("n", "<leader>d", vim.lsp.buf.definition, keymap_opts)
					vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, keymap_opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, keymap_opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, keymap_opts)
					vim.keymap.set("n", "<leader>rf", vim.lsp.buf.references, keymap_opts)
				end,
			})

			-- setup servers
			local servers = opts.servers
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				cmp_nvim_lsp.default_capabilities()
			)

			local function setup(server)
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(capabilities),
				}, servers[server] or {})

				require("lspconfig")[server].setup(server_opts)
			end

			-- get all the servers that are available thourgh mason-lspconfig
			local mlsp = require("mason-lspconfig")
			local all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)

			local ensure_installed = {} ---@type string[]
			for server, server_opts in pairs(servers) do
				if server_opts then
					server_opts = server_opts == true and {} or server_opts
					-- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
					if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
						setup(server)
					else
						ensure_installed[#ensure_installed + 1] = server
					end
				end
			end

			mlsp.setup({ ensure_installed = ensure_installed, handlers = { setup } })
		end,
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"prettierd",
				"stylua",
				"isort",
				"black",
				"goimports",
				"sql-formatter",
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},
	{
		"nvimtools/none-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "mason.nvim" },
		opts = function()
			local nls = require("null-ls")
			return {
				sources = {
					nls.builtins.formatting.gofmt,
					nls.builtins.formatting.goimports,
					nls.builtins.formatting.prettierd,
					nls.builtins.formatting.black,
					nls.builtins.formatting.isort,
					-- nls.builtins.diagnostics.eslint_d,
					nls.builtins.formatting.stylua,
					nls.builtins.formatting.sql_formatter.with({
						extra_args = { "-l", "postgresql" },
					}),
					-- nls.builtins.formatting.prismaFmt
				},
			}
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
		},
		opts = function()
			local cmp = require("cmp")
			local defaults = require("cmp.config.default")()
			local select_opts = { behavior = cmp.SelectBehavior.Select }

			return {
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				preselect = cmp.PreselectMode.Item,
				mapping = {
					-- confirm selection
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-y>"] = cmp.mapping.confirm({ select = false }),

					-- navigate items on the list
					["<Up>"] = cmp.mapping.select_prev_item(select_opts),
					["<Down>"] = cmp.mapping.select_next_item(select_opts),
					["<C-p>"] = cmp.mapping.select_prev_item(select_opts),
					["<C-n>"] = cmp.mapping.select_next_item(select_opts),

					-- scroll up and down in the completion documentation
					["<C-f>"] = cmp.mapping.scroll_docs(5),
					["<C-u>"] = cmp.mapping.scroll_docs(-5),

					-- toggle completion
					["<C-e>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.abort()
						else
							cmp.complete()
						end
					end),

					-- when menu is visible, navigate to next item
					-- when line is empty, insert a tab character
					-- else, activate completion
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item(select_opts)
						elseif check_back_space() then
							fallback()
						else
							cmp.complete()
						end
					end, { "i", "s" }),

					-- when menu is visible, navigate to previous item on list
					-- else, revert to default behavior
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item(select_opts)
						else
							fallback()
						end
					end, { "i", "s" }),
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp", max_item_count = 50 },
					{ name = "nvim_lua" },
					{ name = "path" },
				}),
				formatting = {
					fields = { "abbr", "menu", "kind" },
					format = function(entry, item)
						local short_name = {
							nvim_lsp = "LSP",
							nvim_lua = "nvim",
						}

						local menu_name = short_name[entry.source.name] or entry.source.name

						item.menu = string.format("[%s]", menu_name)
						return item
					end,
				},
				sorting = defaults.sorting,
			}
		end,
	},
	{
		"ray-x/lsp_signature.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		opts = {
			bind = true,
			doc_lines = 5,
			floating_window = true,
			hint_enable = false,
			handler_opts = { border = "single" },
			extra_trigger_chars = { "(", "," },
		},
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"rafamadriz/friendly-snippets",
			config = function()
				require("luasnip.loaders.from_vscode").lazy_load()
			end,
		},
		opts = {
			history = true,
			delete_check_events = "TextChanged",
		},
		-- stylua: ignore
		keys = {
			{
				"<C-d>",
				function()
					return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
				end,
				expr = true,
				silent = true,
				mode = "i",
			},
			{ "<C-d>", function() require("luasnip").jump(1) end,  mode = "s" },
			{ "<C-b>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
		},
	},
}
