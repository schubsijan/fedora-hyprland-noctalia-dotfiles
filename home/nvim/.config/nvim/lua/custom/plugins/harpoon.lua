-- Ui & Shortcuts, um einfach zwischen Dateien zu wechsenl
return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}
    vim.keymap.set('n', '<leader>h', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'open harpoon window' })
    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():add()
    end, { desc = 'add file to harpoon-list' })
    vim.keymap.set('n', '<leader>p', function()
      harpoon:list():prev()
    end, { desc = 'switch with harpoon to previous File on List' })
    vim.keymap.set('n', '<leader>n', function()
      harpoon:list():next()
    end, { desc = 'switch with harpoon to next File on List' })
    vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
    vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
    vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
    vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
    vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end)
    vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end)
    vim.keymap.set("n", "<leader>7", function() harpoon:list():select(7) end)
    vim.keymap.set("n", "<leader>8", function() harpoon:list():select(8) end)
    vim.keymap.set("n", "<leader>9", function() harpoon:list():select(9) end)
    vim.keymap.set("n", "<leader>0", function() harpoon:list():select(10) end)
  end,
}
