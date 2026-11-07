-- Farben kommen von Noctalia: Das Community-Template "Neovim" erzeugt lua/matugen.lua
-- (nicht im Repo) und lädt offene Sitzungen beim Theme-Wechsel per SIGUSR1 neu.
return {
  "RRethy/base16-nvim",
  lazy = false,
  priority = 1000,
  config = function()
    -- pcall: Vor dem ersten Lauf des Templates (z.B. auf einem neuen Rechner)
    -- fehlt matugen.lua; Neovim startet dann mit seinem Standard-Theme.
    local ok, matugen = pcall(require, "matugen")
    if ok then
      matugen.setup()
    end

    -- base16 löst kein ColorScheme-Ereignis aus. Beim Live-Wechsel nachholen, damit davon
    -- abgeleitete Farben (render-markdown, WinBarTitle) mitwechseln. Die Verzögerung lässt
    -- dem Handler in matugen.lua den Vortritt, der auf dasselbe Signal reagiert.
    vim.api.nvim_create_autocmd("Signal", {
      pattern = "SIGUSR1",
      callback = function()
        vim.defer_fn(function()
          vim.api.nvim_exec_autocmds("ColorScheme", {})
        end, 100)
      end,
      desc = "Noctalia: ColorScheme nach Theme-Wechsel auslösen",
    })
  end,
}
