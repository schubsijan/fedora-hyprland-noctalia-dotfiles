return {
  'akinsho/flutter-tools.nvim',
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'stevearc/dressing.nvim', -- Optional: Macht die Auswahl-Menüs schöner
  },
  config = function()
    require("flutter-tools").setup {
      ui = {
        -- Das "Ui" (User Interface) Verhalten anpassen
        border = "rounded",
      },
      decorations = {
        statusline = {
          app_version = true,
          device = true,
        },
      },
      -- Hier konfigurieren wir, wie der Debugger/Runner sich verhält
      debugger = {
        enabled = false,
      },
      dev_log = {
        enabled = true,
        open_cmd = "tabedit", -- Öffnet Logs in einem neuen Tab statt Split
      },
    }

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.dart",
      callback = function()
        -- vim.schedule schiebt den Befehl ans Ende der aktuellen Event-Loop
        vim.schedule(function()
          vim.cmd("FlutterReload")
          print("Flutter Reload angefordert...")
        end)
      end,
    })
  end,
}
