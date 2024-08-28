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
									enabled = true,
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
					vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, keymap_opts)
					vim.keymap.set("n", "<leader>bs", vim.lsp.buf.signature_help, keymap_opts)
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
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
			"onsails/lspkind.nvim",
		},
		opts = function()
			local cmp = require("cmp")
			local select_opts = { behavior = cmp.SelectBehavior.Select }
			local lspkind = require("lspkind")

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
					["<C-y>"] = cmp.mapping.confirm({ select = false }),
					["<C-p>"] = cmp.mapping.select_prev_item(select_opts),
					["<C-n>"] = cmp.mapping.select_next_item(select_opts),
					["<C-e>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.abort()
						else
							cmp.complete()
						end
					end),
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp", max_item_count = 50 },
					{ name = "luasnip" }, -- For luasnip users.
					{ name = "nvim_lua" },
					{ name = "path" },
				}, { { name = "buffer" } }),
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
					}),
				},
			}
		end,
	},
	{
		"ray-x/lsp_signature.nvim",
		version = "*", -- last release
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
		config = function(_, opts)
			require("lsp_signature").setup(opts)
		end,
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
	{
		"j-hui/fidget.nvim",
		opts = {},
	},
}
