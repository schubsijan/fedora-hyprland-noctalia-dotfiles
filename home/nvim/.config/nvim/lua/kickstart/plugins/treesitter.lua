return {
  {
    'nvim-treesitter/nvim-treesitter',
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

      -- Neuer nvim-treesitter Standard ohne .configs
      require('nvim-treesitter').setup({
        ensure_installed = { 'svelte', 'typescript', 'javascript', 'html', 'css', 'templ' },
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'svelte', 'templ' },
        callback = function(args)
          vim.treesitter.start(args.buf)
        end,
      })
    end,
  },
}
