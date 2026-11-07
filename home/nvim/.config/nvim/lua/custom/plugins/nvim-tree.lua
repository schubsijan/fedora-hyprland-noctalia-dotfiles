-- zeigt mir den Filetree an, in dem ich die Dateien auswählen kann
return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local api = require 'nvim-tree.api'

    require('nvim-tree').setup {
      on_attach = function(bufnr)
        local function opts(desc)
          return {
            desc = 'nvim-tree: ' .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          }
        end
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set('n', '?', api.tree.toggle_help, opts 'Help')
      end,
      filters = {
        custom = { '^.git$' },
      },
      actions = {
        open_file = { quit_on_open = true },
      },
      update_focused_file = {
        enable = true,
        update_cwd = true,
      },
      git = {
        enable = true,
        ignore = true,
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        icons = {
          hint = '',
          info = '',
          warning = '',
          error = '',
        },
      },
    }

    vim.keymap.set('n', '<leader>e', function()
      api.tree.toggle()
    end, { desc = 'toggle Filetree' })
  end,
}
