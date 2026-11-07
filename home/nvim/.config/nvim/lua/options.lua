-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- nicht alle Treffer von Suche hervorheben, sondern nur aktuelles
vim.opt.hlsearch = false
-- beim Suche eintippen schon zu Ergebnissen springen
vim.opt.incsearch = true

-- tabgröße nur auf 2 Leerzeichen setzen
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
-- beim Drücken von Tab stattdessen die entsprechende Anzahl an Leerzeichen einfügen
vim.opt.expandtab = true
-- beim Dücken von Enter auf selbe Tabebene kommen, wie die Zeile aus der ich komme
vim.opt.autoindent = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- alle Dateien im aktuellen Buffer neuladen, wenn sie außerhalb von NVIM geändert werden (dadurch bleiben sie in Sync)
vim.opt.autoread = true
vim.bo.autoread = true

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Tilden am Start von leeren Zeilen entfernen
vim.opt.fillchars = { eob = ' ' }

-- vim: ts=2 sts=2 sw=2 et
