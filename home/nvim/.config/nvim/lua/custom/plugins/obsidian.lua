local vault_dir = vim.fs.normalize '~/Documents/Studium/Masterarbeit/masterarbeit-obsidian'

return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  -- Ohne Vault bricht obsidian.setup() mit "At least one workspace is required!" ab,
  -- darum das Plugin dann gar nicht laden (Prüfung beim nvim-Start)
  cond = function()
    return vim.uv.fs_stat(vault_dir) ~= nil
  end,
  lazy = true,
  ft = 'markdown',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    workspaces = {
      {
        name = 'masterarbeit',
        path = vault_dir,
      },
    },
    ui = { enable = false }, -- da ich das markview mache
    frontmatter = { enabled = false },
    legacy_commands = false,
    footer = {
      format = '{{backlinks}} backlinks',
    },
  },
  config = function(_, opts)
    require('obsidian').setup(opts)
    -- Titelfarbe aus dem aktiven Theme ableiten (Rot-Ton), wechselt mit dem Noctalia-Theme mit
    local function set_winbar_title_hl()
      local fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticError', link = false }).fg
      vim.api.nvim_set_hl(0, 'WinBarTitle', { fg = fg, bold = true })
    end
    set_winbar_title_hl()
    vim.api.nvim_create_autocmd('ColorScheme', {
      callback = set_winbar_title_hl,
      desc = 'obsidian: WinBarTitle ans Colorscheme anpassen',
    })
    vim.opt_local.conceallevel = 2
    vim.keymap.set('n', '<leader>oo', '<cmd>Obsidian backlinks<cr>', { desc = 'Backlinks' })

    local vault_path = opts.workspaces[1].path

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('obsidian-gd', { clear = true }),
      callback = function(args)
        local buf = args.buf
        local filepath = vim.api.nvim_buf_get_name(buf)
        if not filepath:find(vault_path, 1, true) then return end
        vim.keymap.set('n', 'gd', function()
          local zotero = require 'custom.scripts.zotero'
          if zotero.open_in_zotero() then
            return
          end
          local word = vim.fn.expand '<cWORD>'
          if word:sub(1, 1) == '#' then
            vim.cmd('Obsidian tags ' .. word:sub(2))
          else
            vim.lsp.buf.definition()
          end
        end, { buffer = buf, desc = 'Go to Zotero/definition/tag' })
      end,
    })

    vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
      pattern = 'markdown',
      callback = function(args)
        local buf = args.buf
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local filepath = vim.api.nvim_buf_get_name(buf)
        if filepath:find(vault_path, 1, true) then
          for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            vim.wo[win].cursorline = false
            vim.wo[win].concealcursor = 'n'
            vim.wo[win].number = false
            vim.wo[win].relativenumber = false
            vim.wo[win].winbar = '%#WinBarTitle# ' .. vim.fn.fnamemodify(filepath, ':t:r') .. ' %< %*'
          end
        end
      end,
    })
  end,
}
