return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    dependencies = {
      'vrischmann/tree-sitter-templ',
    },
    build = ':TSUpdate',
    config = function()
      vim.filetype.add({
        extension = {
          templ = "templ",
        },
      })

      -- main-Branch: setup() kennt kein ensure_installed/highlight mehr,
      -- Parser werden explizit installiert (async, bereits installierte werden übersprungen).
      -- svelte braucht html/css/javascript/typescript für Vererbung + Injections.
      require('nvim-treesitter').install({
        'svelte', 'html', 'css', 'javascript', 'typescript', 'tsx',
        'templ', 'go', 'lua', 'luadoc', 'vim', 'vimdoc', 'query',
        'markdown', 'markdown_inline', 'bash', 'json', 'yaml', 'toml',
      })

      -- Highlighting + Indent für jede Sprache, für die ein Parser vorhanden ist
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang or not pcall(vim.treesitter.start, args.buf, lang) then
            return
          end
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
