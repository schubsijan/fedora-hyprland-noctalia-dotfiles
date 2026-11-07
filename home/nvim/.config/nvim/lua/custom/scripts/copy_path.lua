local M = {}

--- Ermittelt das Projekt-Root.
--- 1. `git rev-parse --show-toplevel` (wenn im Git-Repo)
--- 2. Fallback: aktuelles Arbeitsverzeichnis (cwd)
---@return string root absoluter Pfad zum Root
function M.get_root()
  local git_root = vim.trim(vim.fn.system { 'git', 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error == 0 and git_root ~= '' then
    return git_root
  end
  -- Fallback: cwd (oder nvim 0.10+ vim.fs.root wenn verfügbar)
  if vim.fs and vim.fs.root then
    local cwd = vim.fn.expand '%:p:h'
    if cwd ~= '' then
      local root = vim.fs.root(cwd, '.git')
      if root then
        return root
      end
    end
  end
  return vim.fn.getcwd()
end

local function notify(msg, level)
  -- mini.notify (in mini.lua per setup aktiviert) zeigt vim.notify als
  -- Floating-Window ohne "Press ENTER". Fallback: direkt vim.notify.
  pcall(vim.notify, msg, level)
end

--- Kopiert den relativen Pfad vom Root zum aktuellen File ins System-Clipboard (+ Register)
function M.copy_relative_path()
  local filepath = vim.fn.expand '%:p'
  if filepath == '' then
    notify('Kein File im aktuellen Buffer', vim.log.levels.WARN)
    return
  end

  local root = M.get_root()
  -- Normalisierung: trailing slash entfernen
  root = root:gsub('/+$', '')

  local relative
  if filepath:sub(1, #root) == root then
    relative = filepath:sub(#root + 2)
    -- Falls File == Root (z.B. Root selbst), Fallback auf filename
    if relative == '' then
      relative = vim.fn.fnamemodify(filepath, ':t')
    end
  else
    -- File liegt außerhalb des Roots -> relativ zu cwd oder absoluten Pfad als Fallback
    relative = vim.fn.fnamemodify(filepath, ':.')
    if relative == '' or relative == filepath then
      relative = filepath
    end
  end

  vim.fn.setreg('+', relative)
  -- optional auch ins unnamed register für einfaches p
  vim.fn.setreg('"', relative)

  notify('Pfad kopiert: ' .. relative, vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>cc', M.copy_relative_path, { desc = 'Pfad (relativ zum Root) ins Clipboard kopieren' })

return M
