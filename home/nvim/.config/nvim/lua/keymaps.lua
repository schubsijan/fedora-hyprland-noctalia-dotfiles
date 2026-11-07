-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, { desc = '[L]ist diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- im normalen Modus soll strg+a alles Markieren
vim.keymap.set('n', '<c-a>', 'ggVG')

-- leader-key+{q|w} soll das selbe manchen wie `:q` und `:w`
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { desc = 'quit NeoVim' })
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { desc = 'save current File' })

-- tippen von "ii" im insert-Modus hat den selben Effect, wie Ecape drücken (verlässt also den instert-Modus)
vim.keymap.set('i', 'ii', '<Esc>')

-- wenn man im Visual-Mode Zeilen gehighlightet hat kann man sie mit J oder K nach oben bzw. unter verschieben
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- wenn man in Normal-Mode über einem Wort ist und <leader>rw drückt, dann kommt man in ein einfaches Menu, dass alle Wörter dieser Art im Filer ersetzt
vim.keymap.set('n', '<leader>rw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = 'replace all instances of word under cursor' })

-- <leader>y & <leader>yy um ins System-Clipboard zu kopieren sonst nur innerhalb von Vim
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], { desc = 'In System clipboard kopieren' })
vim.keymap.set('n', '<leader>yy', [["+Y]], { desc = 'Zeile in System clipboard kopieren' })
-- <leader>m um das dannachfolgende (meist d) nicht in clipboard von vim zu packen, sondern einfach nur zu löschen
vim.keymap.set({ 'n', 'v' }, '<leader>m', [["_d]], { desc = 'Löschung nicht in clipboard' })

-- wenn <lead>p dann zwar pasten aber das gehighlighte Wort wird nicht in den buffer gepackt
vim.keymap.set('x', '<leader>p', '"_dP', { desc = 'Pasten, aber gehighlightetes Wort nicht in buffer' })
