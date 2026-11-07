-- "gkk" to comment visual regions/lines
return {
  {
    'numToStr/Comment.nvim',
    opts = {
      toggler = {
        ---Line-comment toggle keymap
        line = 'gkk',
        ---Block-comment toggle keymap
        block = 'gbk',
      },
      ---LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
        ---Line-comment keymap
        line = 'gk',
        ---Block-comment keymap
        block = 'gb',
      },
      ---LHS of extra mappings
      extra = {
        ---Add comment on the line above
        above = 'gkO',
        ---Add comment on the line below
        below = 'gko',
        ---Add comment at the end of line
        eol = 'gkA',
      },
    },
  },
}
