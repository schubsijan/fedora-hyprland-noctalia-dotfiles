-- NOTE: Plugins can specify dependencies.
--
-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.
--
-- Use the `dependencies` key to specify the dependencies of a particular plugin

return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons',            enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          preview = {
            treesitter = false,
          },
          buffer_previewer_maker = function(filepath, bufnr, opts)
            local default = require('telescope.previewers').buffer_previewer_maker
            default(filepath, bufnr, opts)
            if filepath:match('%.md$') then
              vim.bo[bufnr].filetype = 'markdown'
              vim.bo[bufnr].textwidth = 80
              if opts.winid and vim.api.nvim_win_is_valid(opts.winid) then
                vim.wo[opts.winid].wrap = true
                vim.wo[opts.winid].linebreak = true
              end
              vim.schedule(function()
                if vim.api.nvim_buf_is_valid(bufnr) then
                  local ok, manager = pcall(require, 'render-markdown.core.manager')
                  if ok then
                    manager.attach(bufnr)
                  end
                end
              end)
            end
          end,
        },
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        pickers = {
          find_files = {
            file_ignore_patterns = { 'node_modules', '.git' },
          },
        },
        live_grep = {
          find_files = {
            file_ignore_patterns = { 'node_modules', '.git' },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      -- `<leader>ff` drücken, um Finde-File-Suchschlitz zu öffnen
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind in all Files by [G]rep' })
      vim.keymap.set('n', '<leader>fp', builtin.help_tags, { desc = '[F]ind in Hel[p]' })
      vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind in [K]eymaps' })
      vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]elect Telescope' })
      vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind with current [W]ord' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind in [D]iagnostics' })
      vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind in [R]esume' })
      vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>fi', builtin.git_files, { desc = '[F]ind Files in G[i]t' })
      vim.keymap.set('n', '<leader>fh', function()
        require('telescope.builtin').lsp_document_symbols({
          symbol_width = 90,
          sorting_strategy = 'ascending',
          layout_config = {
            prompt_position = 'top'
          }
        })
      end, { desc = '[F]ind [H]eading in current Document' })
      vim.keymap.set('n', '<leader>gf', function()
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local make_entry = require('telescope.make_entry')
        local utils = require('telescope.utils')
        local lsp = vim.lsp
        local channel = require('plenary.async.control').channel

        local opts = { symbols = { 'function', 'method' } }
        -- Project-Root bestimmen (nur Dateien darunter anzeigen - filtert stdlib / GOPATH / Module-Cache)
        local project_root = vim.fn.system({ 'git', 'rev-parse', '--show-toplevel' }):gsub('\n', '')
        if vim.v.shell_error ~= 0 or project_root == '' then
          -- Fallback: LSP root oder cwd
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          project_root = (clients[1] and (clients[1].config.root_dir or clients[1].root_dir)) or vim.fn.getcwd()
        end
        project_root = vim.fs.normalize(project_root)
        if project_root:sub(-1) ~= '/' then project_root = project_root .. '/' end
        -- Cache für git check-ignore, damit nicht jede Eingabe erneut prüft
        local git_cache = {}
        local is_git_repo = vim.fn.system({ 'git', 'rev-parse', '--is-inside-work-tree' }):match('true') ~= nil
        local function is_ignored(path)
          if not is_git_repo then return false end
          if git_cache[path] ~= nil then return git_cache[path] end
          vim.fn.system({ 'git', 'check-ignore', '-q', path })
          local ignored = vim.v.shell_error == 0
          git_cache[path] = ignored
          return ignored
        end

        local cancel = function() end
        local function get_filtered_requester(bufnr, filter_opts)
          return function(prompt)
            local tx, rx = channel.oneshot()
            cancel()
            cancel = lsp.buf_request_all(bufnr, 'workspace/symbol', { query = prompt }, tx)
            local results = rx()
            local locations = {}
            for client_id, res in pairs(results) do
              if res.result then
                local client = assert(lsp.get_client_by_id(client_id))
                vim.list_extend(locations, lsp.util.symbols_to_items(res.result, bufnr, client.offset_encoding))
              elseif res.error then
                utils.notify('lsp_dynamic_workspace_symbols', { msg = res.error.message, level = 'ERROR' })
              end
            end
            if not vim.tbl_isempty(locations) then
              locations = utils.filter_symbols(locations, filter_opts) or {}
              -- 1. nur Dateien innerhalb project_root behalten (filtert stdlib / /usr/local/go / GOPATH/pkg/mod)
              locations = vim.tbl_filter(function(e)
                local fname = vim.fs.normalize(e.filename)
                return fname:sub(1, #project_root) == project_root
              end, locations)
              -- 2. nachträglich .gitignore filtern
              locations = vim.tbl_filter(function(e) return not is_ignored(e.filename) end, locations)
            end
            return locations
          end
        end

        pickers
          .new(opts, {
            prompt_title = 'Go Functions (ohne .gitignore)',
            finder = finders.new_dynamic({
              entry_maker = opts.entry_maker or make_entry.gen_from_lsp_symbols(opts),
              fn = get_filtered_requester(vim.api.nvim_get_current_buf(), opts),
            }),
            previewer = conf.qflist_previewer(opts),
            sorter = conf.generic_sorter(opts),
          })
          :find()
      end, { desc = '[G]o workspace [F]unctions (ohne .gitignore)' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>f/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[F]ind [/] in Open Files' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
