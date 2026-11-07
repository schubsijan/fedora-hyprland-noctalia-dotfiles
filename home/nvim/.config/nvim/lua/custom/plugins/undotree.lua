return {
  'mbbill/undotree',
  config = function()
    -- Plattformspezifische DiffCommand Konfiguration
    if vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1 then
      vim.g.undotree_DiffCommand = 'FC'
    else
      -- Auf Linux/macOS das Standard diff-tool verwenden
      vim.g.undotree_DiffCommand = 'diff'
    end
    vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'toggle Undotree' })
    -- undotree erlauben auch noch nach langer Zeit Dinge zu löschen
    vim.opt.swapfile = false
    vim.opt.backup = false
    vim.opt.undofile = true
  end,
}
