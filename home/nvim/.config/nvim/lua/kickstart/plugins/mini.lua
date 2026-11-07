return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        options = {
          -- ... your lualine config
          theme = 'onenord',
          -- ... your lualine config
        },
      }

      local function apply_aether_statusline()
        if vim.g.colors_name == 'aether' then
          vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { bg = '#ecebbd' })
        end
      end

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = apply_aether_statusline,
      })
      apply_aether_statusline()

      -- 1. MODE: "N", "I", "V" mit korrekter Farbe
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_mode = function(args)
        local mode_map = {
          ['n'] = 'N',
          ['i'] = 'I',
          ['v'] = 'V',
          ['V'] = 'V-L',
          ['\22'] = 'V-B',
          ['c'] = 'C',
          ['R'] = 'R',
          ['t'] = 'T',
        }
        local mode = vim.fn.mode()
        local text = mode_map[mode] or mode

        -- Farbe je nach Modus wählen
        local mode_hl = 'MiniStatuslineModeNormal'
        if mode == 'i' then
          mode_hl = 'MiniStatuslineModeInsert'
        elseif mode:find('[vV\22]') then
          mode_hl = 'MiniStatuslineModeVisual'
        elseif mode == 'R' then
          mode_hl = 'MiniStatuslineModeReplace'
        elseif mode == 'c' then
          mode_hl = 'MiniStatuslineModeCommand'
        end

        return text, mode_hl
      end

      -- 2. FILEINFO: Icon + Dateityp (mit Fix für den Fehler)
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_fileinfo = function(args)
        local filetype = vim.bo.filetype
        if filetype == '' then return '' end

        local icon = ''
        -- Versuche das Icon über nvim-web-devicons zu laden (Standard in Kickstart)
        local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
        if has_devicons then
          icon = devicons.get_icon(vim.fn.expand('%:t'), filetype, { default = true })
        end

        -- Falls kein Icon gefunden wurde, leer lassen
        icon = icon or ''
        -- Abstand nur hinzufügen, wenn ein Icon da ist
        if icon ~= '' then icon = icon .. ' ' end

        -- Gibt Text UND die Highlight-Gruppe 'MiniStatuslineFileinfo' zurück
        return icon .. filetype, 'MiniStatuslineFileinfo'
      end

      -- 3. LOCATION: Zeile:Spalte mit Hintergrund
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        -- Gibt Text UND die Highlight-Gruppe 'MiniStatuslineDevinfo' zurück
        return '%2l:%-2v', 'MiniStatuslineDevinfo'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
      require('mini.pairs').setup()

      -- Notifications als Floating-Window (verhindert "Press ENTER" bei vim.notify)
      -- Muss nach dem Setup von mini.nvim erfolgen.
      require('mini.notify').setup {
        content = {
          -- Zeitstempel ausblenden: nur die reine Nachricht anzeigen
          format = function(notif)
            return notif.msg
          end,
        },
      }
      vim.api.nvim_create_user_command('Messages', function()
        local all = MiniNotify.get_all()
        if not next(all) then
          vim.api.nvim_echo({ { 'Keine Notifications', 'None' } }, true, {})
          return
        end
        local arr = {}
        for _, v in pairs(all) do
          table.insert(arr, v)
        end
        table.sort(arr, function(a, b)
          return a.ts_update < b.ts_update
        end)
        -- wie :messages unten in der Cmdline anzeigen, nicht als Buffer
        local lines = {}
        for _, n in ipairs(arr) do
          table.insert(lines, n.msg)
        end
        local text = table.concat(lines, '\n')
        vim.api.nvim_echo({ { text, 'None' } }, true, {})
      end, { desc = 'MiniNotify History unten anzeigen (wie :messages)' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
