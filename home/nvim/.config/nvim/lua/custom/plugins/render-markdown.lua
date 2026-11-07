return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  -- LaTeX-Rendering benötigt: (1) latex treesitter parser → :TSInstall latex
  -- LaTeX-Rendering benötigt: (1) latex treesitter parser → :TSInstall latex
  --                          (2) latex2text (von pylatexenc) → pip install pylatexenc
  opts = {
    preset = 'obsidian',
    on = {
      render = function(ctx)
        local ns = vim.api.nvim_create_namespace('rmd-arrows')
        vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)
        local top = vim.fn.line('w0') - 1
        local bot = vim.fn.line('w$') - 1
        local cursor = vim.api.nvim_win_get_cursor(ctx.win)
        local lines = vim.api.nvim_buf_get_lines(ctx.buf, top, bot + 1, false)
        local arrows = { { '<->', '↔' }, { '<=>', '⇔' }, { '->', '→' }, { '<-', '←' }, { '=>', '⇒' }, { '<=', '⇐' } }
        for i, line in ipairs(lines) do
          local row = top + i - 1
          if row ~= cursor[1] - 1 then
            local pos = 1
            while pos <= #line do
              local found = false
              for _, a in ipairs(arrows) do
                local pat, cchar = a[1], a[2]
                if #line >= pos + #pat - 1 and line:sub(pos, pos + #pat - 1) == pat then
                  vim.api.nvim_buf_set_extmark(ctx.buf, ns, row, pos - 1, {
                    end_row = row,
                    end_col = pos - 1 + #pat,
                    conceal = '',
                    virt_text = { { cchar } },
                    virt_text_pos = 'inline',
                    priority = 200,
                  })
                  pos = pos + #pat
                  found = true
                  break
                end
              end
              if not found then
                pos = pos + 1
              end
            end
          end
          -- Hide emphasis markers on non-cursor lines
          if row ~= cursor[1] - 1 then
            local mpos = 1
            while mpos <= #line do
              local s, e = line:find('[*_]+', mpos)
              if not s then break end
              vim.api.nvim_buf_set_extmark(ctx.buf, ns, row, s - 1, {
                end_row = row, end_col = e,
                conceal = '',
                virt_text = { { '' } },
                virt_text_pos = 'inline',
                priority = 200,
              })
              mpos = e + 1
            end
          end
          local link_pos = 1
          while link_pos do
            local s, e, link_text = line:find('%[([^%]]*)%]%(([^)]*)%)', link_pos)
            if s then
              local link_start_0 = s - 1
              local link_end_0 = e
              local on_link = row == cursor[1] - 1 and cursor[2] >= link_start_0 and cursor[2] < link_end_0
              if not on_link and e > s then
                -- hide `[`
                vim.api.nvim_buf_set_extmark(ctx.buf, ns, row, s - 1, {
                    end_row = row, end_col = s,
                    conceal = '',
                    virt_text = { { '' } },
                    virt_text_pos = 'inline',
                    priority = 10000,
                })
                -- hide `]`
                vim.api.nvim_buf_set_extmark(ctx.buf, ns, row, s + #link_text, {
                    end_row = row, end_col = s + #link_text + 1,
                    conceal = '',
                    virt_text = { { '' } },
                    virt_text_pos = 'inline',
                    priority = 10000,
                })
                -- hide `(url)`
                vim.api.nvim_buf_set_extmark(ctx.buf, ns, row, s + #link_text + 1, {
                  end_row = row,
                  end_col = e,
                  conceal = '',
                  virt_text = { { '' } },
                  virt_text_pos = 'inline',
                  priority = 10000,
                })
              end
              link_pos = e + 1
            else
              link_pos = nil
            end
          end
        end
      end,
      clear = function(ctx)
        local ns = vim.api.nvim_create_namespace('rmd-arrows')
        vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)
      end,
    },
    anti_conceal = {
      ignore = {
        head_background = true,
        head_border = true,
        code_background = true,
        indent = true,
        sign = true,
        virtual_lines = true,
      },
    },
    completions = { lsp = { enabled = true } },
    heading = {
      sign = true,
      signs = { '#' },
      icons = { '', '', '', '', '', '' },
      position = 'inline',
      foregrounds = {
        'RenderMarkdownH1',
        'RenderMarkdownH2',
        'RenderMarkdownH3',
        'RenderMarkdownH4',
        'RenderMarkdownH5',
        'RenderMarkdownH6',
      },
    },
    code = {
      sign = false,
      width = 'block',
      left_pad = 1,
      right_pad = 1,
    },
    dash = {
      icon = '',
      width = 'full',
    },
    bullet = {
      icons = { '' },
      right_pad = 0.9,
    },


    link = {
      footnote = {
        icon = '',
      },
      image = '',
      email = '',
      hyperlink = '',
      wiki = {
        icon = '',
        scope_highlight = 'my-link',
      },
      custom = {
        web = { icon = '', pattern = '^http' },
        apple = { icon = '', pattern = 'apple%.com', kind = 'url' },
        discord = { icon = '', pattern = 'discord%.com', kind = 'url' },
        github = { icon = '', pattern = 'github%.com', kind = 'url' },
        gitlab = { icon = '', pattern = 'gitlab%.com', kind = 'url' },
        google = { icon = '', pattern = 'google%.com', kind = 'url' },
        hackernews = { icon = '', pattern = 'ycombinator%.com', kind = 'url' },
        linkedin = { icon = '', pattern = 'linkedin%.com', kind = 'url' },
        microsoft = { icon = '', pattern = 'microsoft%.com', kind = 'url' },
        neovim = { icon = '', pattern = 'neovim%.io', kind = 'url' },
        reddit = { icon = '', pattern = 'reddit%.com', kind = 'url' },
        slack = { icon = '', pattern = 'slack%.com', kind = 'url' },
        stackoverflow = { icon = '', pattern = 'stackoverflow%.com', kind = 'url' },
        steam = { icon = '', pattern = 'steampowered%.com', kind = 'url' },
        twitter = { icon = '', pattern = 'twitter%.com', kind = 'url' },
        wikipedia = { icon = '', pattern = 'wikipedia%.org', kind = 'url' },
        x = { icon = '', pattern = 'x%.com', kind = 'url' },
        youtube = { icon = '', pattern = 'youtube[^.]*%.com', kind = 'url' },
        youtube_short = { icon = '', pattern = 'youtu%.be', kind = 'url' },
      },
    },

    pipe_table = { preset = 'round' },
    quote = { repeat_linebreak = true },
    win_options = {
      concealcursor = {
        rendered = 'nc',
      },
      wrap = {
        default = vim.o.wrap,
        rendered = true,
      },
      linebreak = {
        default = vim.o.linebreak,
        rendered = true,
      },
      showbreak = {
        default = '',
        rendered = '  ',
      },
      breakindent = {
        default = false,
        rendered = true,
      },
      breakindentopt = {
        default = '',
        rendered = '',
      },
    },
  },
  config = function(_, opts)
    local render = require 'render-markdown'
    render.setup(opts)
    local function hl(name)
      return vim.api.nvim_get_hl(0, { name = name })
    end

    local function pick(groups, attr)
      for _, name in ipairs(groups) do
        local h = hl(name)
        if h[attr] then
          return h[attr]
        end
      end
      return nil
    end

    local function setup_highlights()
      local normal_bg = hl('Normal').bg

      -- H1 red, H2 green, H3 orange, H4 blue, H5 purple, H6 cyan
      -- Jeweils exakter Wert aus dem aktiven Nvim-Theme (terminal_color_* / Standard-HLs).
      local function term(idx)
        local c = vim.g['terminal_color_' .. idx]
        if c and c:match('^#%x%x%x%x%x%x$') then return c end
        return nil
      end

      local heading_defs = {
        H1 = { term = 1, groups = { 'DiagnosticError', 'ErrorMsg', 'Red' } }, -- red
        H2 = { term = 2, groups = { 'String', 'DiagnosticOk', 'DiffAdd', 'Green' } }, -- green
        H3 = { term = 3, groups = { 'Number', 'Constant', 'Orange', 'DiagnosticWarn' } }, -- orange
        H4 = { term = 4, groups = { 'Function', 'Identifier', 'DiagnosticInfo', 'Blue' } }, -- blue
        H5 = { term = 5, groups = { 'Statement', 'Keyword', 'Exception', 'Purple', 'Magenta' } }, -- purple
        H6 = { term = 6, groups = { 'Special', 'DiagnosticHint', 'Cyan' } }, -- cyan
      }

      local fallback_sources = {
        H1 = { '@markup.heading.1.markdown', 'Title' },
        H2 = { '@markup.heading.2.markdown', 'Identifier' },
        H3 = { '@markup.heading.3.markdown', 'Special' },
        H4 = { '@markup.heading.4.markdown', 'Statement' },
        H5 = { '@markup.heading.5.markdown', '@markup.heading', 'NonText' },
        H6 = { '@markup.heading.6.markdown', '@markup.heading', 'Comment' },
      }

      for level, def in pairs(heading_defs) do
        local fg = nil
        -- H3: Orange via Number-HL bevorzugen (terminal_color_3 ist oft yellow)
        if level == 'H3' then
          fg = pick(def.groups, 'fg')
          if not fg then fg = term(def.term) end
        else
          fg = term(def.term)
          if not fg then fg = pick(def.groups, 'fg') end
        end
        if not fg then fg = pick(fallback_sources[level], 'fg') end
        if fg then
          vim.api.nvim_set_hl(0, 'RenderMarkdown' .. level, { fg = fg, bold = true })
          vim.api.nvim_set_hl(0, 'RenderMarkdown' .. level .. 'Bg', { fg = fg, bg = normal_bg, bold = true })
        end
      end

      local italic_fg = pick({ '@markup.italic', 'Type' }, 'fg')
      if italic_fg then
        vim.api.nvim_set_hl(0, '@markup.italic', { fg = italic_fg, italic = true })
      end

      local bullet_fg = pick({ 'NonText', 'Comment' }, 'fg')
      if bullet_fg then
        vim.api.nvim_set_hl(0, 'RenderMarkdownBullet', { fg = bullet_fg })
      end

      local quote_fg = pick({ '@markup.quote', 'String', 'Comment' }, 'fg')
      if quote_fg then
        for i = 1, 6 do
          vim.api.nvim_set_hl(0, 'RenderMarkdownQuote' .. i, { fg = quote_fg })
        end
      end

      vim.api.nvim_set_hl(0, 'RenderMarkdownInlineHighlight', {
        bg = pick({ 'Visual', 'CursorLine' }, 'bg') or normal_bg,
        fg = pick({ 'Visual', 'Normal' }, 'fg'),
      })

      local link_fg = pick({ '@markup.link', '@markup.link.markdown', '@string.special.url', 'Identifier' }, 'fg')
      if link_fg then
        vim.api.nvim_set_hl(0, '@markup.link.label.markdown_inline', { fg = link_fg, underline = true })
        vim.api.nvim_set_hl(0, '@markup.link.markdown_inline', { fg = link_fg, underline = true })
        vim.api.nvim_set_hl(0, 'RenderMarkdownLinkTitle', { fg = link_fg, underline = true })
        vim.api.nvim_set_hl(0, 'my-link', { fg = link_fg, underline = false, nocombine = true })
        vim.api.nvim_set_hl(0, 'RenderMarkdownLink', { fg = link_fg, underline = false })
      end
    end

    setup_highlights()

    vim.treesitter.query.set('markdown_inline', 'highlights', [[
(code_span) @markup.raw @nospell

(emphasis) @markup.italic

(strong_emphasis) @markup.strong

(strikethrough) @markup.strikethrough

(shortcut_link
  (link_text) @nospell)

[
  (backslash_escape)
  (hard_line_break)
] @string.escape

; Conceal codeblock and text style markers
([
  (code_span_delimiter)
] @conceal
  (#set! conceal ""))

; Inline links handled by on.render
(inline_link
  [
    "["
    "]"
    "("
    (link_destination)
    ")"
  ] @markup.link)

[
  (link_label)
  (link_text)
  (link_title)
  (image_description)
] @markup.link.label

((inline_link
  (link_destination) @_url) @_label
  (#set! @_label url @_url))

((image
  (link_destination) @_url) @_label
  (#set! @_label url @_url))

; Conceal image links
(image
  [
    "!"
    "["
    "]"
    "("
    (link_destination)
    ")"
  ] @markup.link
  (#set! conceal ""))

; Conceal full reference links
(full_reference_link
  [
    "["
    "]"
    (link_label)
  ] @markup.link
  (#set! conceal ""))

; Conceal collapsed reference links
(collapsed_reference_link
  [
    "["
    "]"
  ] @markup.link
  (#set! conceal ""))

; Conceal shortcut links - handled by on.render
(shortcut_link
  [
    "["
    "]"
  ] @markup.link)

[
  (link_destination)
  (uri_autolink)
  (email_autolink)
] @markup.link.url @nospell

((uri_autolink) @_url
  (#offset! @_url 0 1 0 -1)
  (#set! @_url url @_url))

(entity_reference) @nospell

((entity_reference) @character.special
  (#eq? @character.special "&nbsp;")
  (#set! conceal " "))

((entity_reference) @character.special
  (#eq? @character.special "&lt;")
  (#set! conceal "<"))

((entity_reference) @character.special
  (#eq? @character.special "&gt;")
  (#set! conceal ">"))

((entity_reference) @character.special
  (#eq? @character.special "&amp;")
  (#set! conceal "&"))

((entity_reference) @character.special
  (#eq? @character.special "&quot;")
  (#set! conceal "\""))

((entity_reference) @character.special
  (#any-of? @character.special "&ensp;" "&emsp;")
  (#set! conceal " "))
]])

    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function()
        vim.schedule(setup_highlights)
      end,
      desc = 'render-markdown: Highlights ans Colorscheme anpassen',
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        vim.bo.formatoptions = vim.bo.formatoptions .. 'r'
        vim.bo.comments = 'b:-,b:*,b:+,b:1.,b:1)'
        vim.bo.autoindent = true
      end,
      desc = 'markdown: Bullet-Listen auf Enter fortsetzen',
    })

    local orig_definition = vim.lsp.buf.definition
    function vim.lsp.buf.definition()
      if vim.tbl_contains({ 'markdown', 'pandoc', 'rmd' }, vim.bo.filetype) then
        local zotero = require 'custom.scripts.zotero'
        if zotero.open_in_zotero() then
          return
        end

        local line = vim.fn.getline('.')
        local col = vim.fn.col('.') - 1
        local pos = 1
        while pos <= #line do
          local link_start, link_end, url = line:find('%b[]%(([^)]+)%)', pos)
          if not link_start then break end
          if col >= link_start - 1 and col <= link_end - 1 then
            vim.fn.system({ 'xdg-open', url })
            return
          end
          pos = link_end + 1
        end
      end

      orig_definition()
    end
  end,
  ft = { 'markdown' },
}
