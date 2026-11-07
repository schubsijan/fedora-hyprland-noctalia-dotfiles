-- Highlight todo, notes, etc in comments
return {
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('todo-comments').setup {
        highlight = {
          pattern = [[.*<(KEYWORDS)\s*]], -- pattern or table of patterns, used for highlighting (vim regex)
        },
        search = {
          pattern = [[\b(KEYWORDS)\b]], -- ripgrep regex
        },
      }
      vim.keymap.set('n', '<leader>lt', '<cmd>TodoTelescope<CR>', { desc = 'List all Tasks in project' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
