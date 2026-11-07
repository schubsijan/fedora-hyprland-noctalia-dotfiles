-- nice documentation for setting up a LSP in nvim: https://lsp-zero.netlify.app/docs/getting-started.html
return {
  {
    'williamboman/mason.nvim',
    lazy = false,
    opts = {},
  },
  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-path',
      "onsails/lspkind.nvim", -- vs-code like pictograms
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets"
    },
    event = 'InsertEnter',
    config = function()
      local cmp = require('cmp')
      require('luasnip.loaders.from_vscode').lazy_load()
      cmp.setup({
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' }
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-k>'] = cmp.mapping.confirm { select = true },
          -- Navigate between completion items
          ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
          ['<C-n>'] = cmp.mapping.select_next_item({ behavior = 'select' }),
          -- mit <C-e> abbrechen können
          ['<C-e>'] = cmp.mapping.abort(),

          -- Jump to the next snippet placeholder
          ['<C-l>'] = cmp.mapping(function(fallback)
            local luasnip = require('luasnip')
            if luasnip.locally_jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { 'i', 's' }),
          -- Jump to the previous snippet placeholder
          ['<C-h>'] = cmp.mapping(function(fallback)
            local luasnip = require('luasnip')
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),

          -- `Enter` key to confirm completion

          -- Ctrl+Space to trigger completion menu
          ['<C-Space>'] = cmp.mapping.complete(),

          -- Scroll up and down in the completion documentation
          ['<C-u>'] = cmp.mapping.scroll_docs(-3),
          ['<C-d>'] = cmp.mapping.scroll_docs(5),
        }),
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = require("lspkind").cmp_format({
            mode = "symbol", -- nur die Symbole anzeigen, nicht auch den Text
            ellipsis_char = "...",
            maxwidth = {
              menu = 51,              -- leading text (labelDetails)
              abbr = 51,              -- actual suggestion item
            },
            show_labelDetails = true, -- show labelDetails in menu. Disabled by default
          }),
        },
      })
    end
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },
      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { "folke/neodev.nvim",                opts = {} },
    },
    init = function()
      -- Reserve a space in the gutter
      -- This will avoid an annoying layout shift in the screen
      vim.opt.signcolumn = 'yes'
    end,
    config = function()
      local lsp_defaults = require('lspconfig').util.default_config

      -- add templ as filetype, so that nvim can attach the lsps
      vim.filetype.add({ extension = { templ = "templ" } })

      -- Add cmp_nvim_lsp capabilities settings to lspconfig
      -- This should be executed before you configure any language server
      lsp_defaults.capabilities = vim.tbl_deep_extend(
        'force',
        lsp_defaults.capabilities,
        require('cmp_nvim_lsp').default_capabilities()
      )

      -- LspAttach is where you enable features that only work
      -- if there is a language server active in the file
      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local opts = { buffer = event.buf }

          vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
          vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
          vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
          vim.keymap.set('n', 'gi', require('telescope.builtin').lsp_implementations, opts)
          vim.keymap.set('n', '<leader>D', require('telescope.builtin').lsp_type_definitions, opts)
          vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
          vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
          vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, opts)
          vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
          vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
          vim.keymap.set({ 'n', 'x' }, '<leader>lf', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
          vim.keymap.set('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
        end,
      })

      require('mason-lspconfig').setup({
        automatic_installation = true,
        ensure_installed = {
          'ts_ls',
          'lua_ls',
          'gopls',
          'html',
          'tailwindcss',
          'eslint',
          'templ',
          'svelte',
        },
        handlers = {
          -- this first function is the "default handler"
          -- it applies to every language server without a "custom handler"
          function(server_name)
            require('lspconfig')[server_name].setup({})
          end,
          -- laguageservers with custom handlers
          lua_ls = function()
            require('lspconfig').lua_ls.setup({
              settings = {
                Lua = {
                  completion = {
                    callSnippet = "Replace",
                  },
                  -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                  -- diagnostics = { disable = { 'missing-fields' } },
                },
              },
            })
          end,
          gopls = function()
            require('lspconfig').gopls.setup({
              filetypes = { "go", "templ" },
              gopls = {
                codelenses = {
                  generate = true,   -- show the `go generate` lens.
                  gc_details = true, -- show a code lens toggling the display of gc's choices.
                  test = true,
                  upgrade_dependency = true,
                  tidy = true,
                },
                completeUnimported = true,
                analyses = {
                  unusedparams = true
                }
              },
            })
          end,
          templ = function()
            require('lspconfig').templ.setup({
              default_config = {
                --cmd = { "templ", "lsp", "-http=localhost:7475", "-log=/Users/adrian/templ.log", "-goplsLog=/Users/adrian/gopls.log" },
                cmd = { 'templ', 'lsp' },
                filetypes = { 'templ' },
                root_dir = require('lspconfig').util.root_pattern('go.mod', '.git'),
                settings = {},
              },
            })
          end,
          html = function()
            require('lspconfig').html.setup({
              filetypes = { "html", "templ" },
            })
          end,
          tailwindcss = function()
            require('lspconfig').tailwindcss.setup({
              filetypes = { "html", "templ" },
              init_options = { userLanguages = { templ = "html" } },
              settings = {
                tailwindCSS = {
                  includeLanguages = {
                    templ = "html",
                  },
                },
              },
            })
          end,
          eslint = function()
            require('lspconfig').eslint.setup({
              enable = true,
              format = { enable = true }, -- this will enable formatting
              packageManager = 'npm',
              autoFixOnSave = true,
              codeActionOnSave = {
                mode = 'all',
                rules = { '!debugger', '!no-only-tests/*' },
              },
              lintTask = {
                enable = true,
              },
            })
          end,
          tsserver = function()
            require('lspconfig').ts_ls.setup({
              settings = {
                typescript = {
                  tsserver = {
                    globalPlugins = {
                      {
                        name = 'typescript-svelte-plugin',
                        location = vim.fn.stdpath('data')
                          .. '/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin',
                        enableForWorkspaceTypeScriptVersions = true,
                      },
                    },
                  },
                },
              },
            })
          end,
          svelte = function()
            require('lspconfig').svelte.setup({
              root_dir = require('lspconfig').util.root_pattern('svelte.config.js', 'package.json', '.git'),
            })
          end,
        }
      })
    end
  }
}
