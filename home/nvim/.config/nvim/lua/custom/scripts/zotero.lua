local M = {}

local port = 23119
local rpc_url = ('http://127.0.0.1:%d/better-bibtex/json-rpc'):format(port)
local csl_json_translator = '36a3b0b5-bad0-4a04-b79b-441c7cef77db'

function M.cite()
  local url = ('http://127.0.0.1:%d/better-bibtex/cayw?format=pandoc&brackets=true'):format(port)
  local ok, result = pcall(vim.fn.system, { 'curl', '-s', '--connect-timeout', '3', url })
  if not ok or vim.v.shell_error ~= 0 then
    vim.notify('Zotero / Better BibTeX nicht erreichbar. Ist Zotero gestartet?', vim.log.levels.ERROR)
    return
  end
  result = vim.trim(result)
  if result == '' then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local new_line = line:sub(1, col) .. result .. line:sub(col + 1)
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row, col + #result })
end

function M.rpc_call(method, params)
  local payload = vim.fn.json_encode({ jsonrpc = '2.0', method = method, params = params })
  local ok, result = pcall(vim.fn.system, {
    'curl', '-s', '--connect-timeout', '3',
    '-H', 'Content-Type: application/json',
    '-d', payload,
    rpc_url,
  })
  if not ok or vim.v.shell_error ~= 0 then return nil end
  local ok2, parsed = pcall(vim.fn.json_decode, result)
  if not ok2 or not parsed or parsed.error then return nil end
  return parsed.result
end

function M.export_csl_items(citekeys, library_id)
  local result = M.rpc_call('item.export', { citekeys, csl_json_translator, library_id })
  if not result then return nil end
  local json_str
  if type(result) == 'table' and #result >= 3 then
    json_str = result[3]
  elseif type(result) == 'string' then
    json_str = result
  else
    return nil
  end
  local ok, data = pcall(vim.fn.json_decode, json_str)
  if not ok or not data or not data.items then return nil end
  return data.items
end

function M.search_item(citekey)
  local results = M.rpc_call('item.search', { citekey })
  if not results then return nil end
  for _, item in ipairs(results) do
    if item.citekey == citekey then
      return item
    end
  end
  return nil
end

function M.citekeys_under_cursor()
  local line = vim.fn.getline('.')
  local col = vim.fn.col('.') - 1
  local citekeys = {}
  for start, key, stop in line:gmatch('()@([%w_%-:%.]+)()') do
    if col >= start - 1 and col <= stop - 1 then
      table.insert(citekeys, key)
    end
  end
  if #citekeys == 0 then
    for keys in line:gmatch('%[([^%[%]]*@[^%[%]]*)%]') do
      local s, e = line:find('%[' .. vim.pesc(keys) .. '%]')
      if s and col >= s - 1 and col <= e - 1 then
        for key in keys:gmatch('@([%w_%-:%.]+)') do
          table.insert(citekeys, key)
        end
      end
    end
  end
  return citekeys
end

function M.open_in_zotero()
  local citekeys = M.citekeys_under_cursor()
  if #citekeys == 0 then return false end

  local groups = M.rpc_call('user.groups', {})
  local group_map = {}
  if groups then
    for _, g in ipairs(groups) do
      group_map[g.name] = g.id
    end
  end

  for _, citekey in ipairs(citekeys) do
    local search_item = M.search_item(citekey)
    if not search_item then
      -- try exporting with library 1 as fallback
      local items = M.export_csl_items({ citekey }, 1)
      if items and #items > 0 then
        M.open_item(items[1])
        return true
      end
    else
      local library_id = 1
      if search_item.libraryID then
        library_id = tonumber(search_item.libraryID) or 1
      elseif search_item.library and group_map[search_item.library] then
        library_id = group_map[search_item.library]
      end

      local items = M.export_csl_items({ citekey }, library_id)
      if items and #items > 0 then
        M.open_item(items[1])
        return true
      end
    end
  end

  vim.notify('Zotero-Eintrag nicht gefunden', vim.log.levels.WARN)
  return false
end

function M.get_citekey_from_uri(zotero_uri, citation_text)
  local item_key = zotero_uri:match('/items/([^/]+)$')

  -- 1) search by author surname extracted from citation text
  if citation_text then
    local surname = citation_text:match('^([^,]+)')
    local year = citation_text:match('(%d%d%d%d)')
    if surname then
      local term = surname
      if year then term = term .. ' ' .. year end
      local results = M.rpc_call('item.search', { term })
      if results then
        for _, item in ipairs(results) do
          if item.citekey then
            local ck = item.citekey:lower()
            if year then ck = ck:match(year) end
            if ck then return item.citekey end
          end
        end
      end
    end
  end

  -- 2) item.citationkey RPC
  if item_key then
    local result = M.rpc_call('item.citationkey', { { '1:' .. item_key } })
    if result then
      for _, v in pairs(result) do
        if v then return v end
      end
    end
  end

  -- 3) full-text search by item key
  if item_key then
    local results = M.rpc_call('item.search', { item_key })
    if results then
      for _, item in ipairs(results) do
        if item.key == item_key or item.id == item_key then
          return item.citekey or item.id
        end
      end
      for _, item in ipairs(results) do
        if item.citekey then return item.citekey end
      end
    end
  end

  return nil
end

function M.transform_zotero_highlight(text)
  if not text or text == '' then return nil end

  text = text:gsub('“', '"'):gsub('”', '"'):gsub('‘', "'"):gsub('’', "'")

  local citation_text, zotero_uri = text:match('%(%[([^%]]+)%]%((zotero://select/[^)]+)%)%)')
  if not citation_text or not zotero_uri then
    return text, 'pattern'
  end

  local citekey = M.get_citekey_from_uri(zotero_uri, citation_text)
  if not citekey then
    return text, 'citekey'
  end

  local year_start = citation_text:find('%d%d%d%d')
  local locator = ''
  if year_start then
    local after = citation_text:sub(year_start + 4)
    locator = after:match('^,%s*(.-)%s*$') or ''
  end

  local pandoc_cite
  if locator ~= '' then
    pandoc_cite = ('[@%s, {%s}]'):format(citekey, locator)
  else
    pandoc_cite = ('[@%s]'):format(citekey)
  end

  text = text:gsub('%(%[([^%]]+)%]%((zotero://select/[^)]+)%)%)', pandoc_cite, 1)
  text = text:gsub('%(%[pdf%]%((zotero://open%-pdf/[^)]+)%)%)', '[~>](%1)')
  return text, 'ok'
end

function M.paste_zotero_highlight()
  local text = vim.fn.getreg('+')
  if text == '' then
    vim.notify('System-Clipboard ist leer', vim.log.levels.WARN)
    return
  end
  local transformed, reason = M.transform_zotero_highlight(text)
  if reason == 'pattern' then
    vim.notify('Kein Zotero-Zitat im Clipboard gefunden', vim.log.levels.WARN)
  elseif reason == 'citekey' then
    vim.notify('Zotero-Citekey nicht aufgelöst. Läuft Zotero + Better BibTeX?', vim.log.levels.WARN)
  end
  M.insert_at_cursor(transformed)
end

function M.paste_zotero_highlight_visual()
  -- yank visual selection into register 'z'
  local saved = vim.fn.getreg('z')
  vim.fn.setreg('z', '')
  pcall(vim.cmd, 'normal! "zy')
  local text = vim.fn.getreg('z')
  if text == '' then
    vim.fn.setreg('z', saved)
    vim.notify('Leere Auswahl', vim.log.levels.WARN)
    return
  end

  local transformed, reason = M.transform_zotero_highlight(text)
  if reason == 'pattern' then
    vim.fn.setreg('z', saved)
    vim.notify('Kein Zotero-Zitat in der Auswahl gefunden', vim.log.levels.WARN)
    return
  end
  if reason == 'citekey' then
    vim.fn.setreg('z', saved)
    vim.notify('Zotero-Citekey nicht aufgelöst. Läuft Zotero + Better BibTeX?', vim.log.levels.WARN)
    return
  end
  if not transformed then
    vim.fn.setreg('z', saved)
    vim.notify('Unbekannter Fehler bei Transformation', vim.log.levels.ERROR)
    return
  end

  -- reselect and replace
  vim.fn.setreg('z', transformed)
  pcall(vim.cmd, 'normal! gv"zp')
  vim.fn.setreg('z', saved)
end

function M.paste_zotero_text()
  local text = vim.fn.getreg('+')
  if text == '' then
    vim.notify('System-Clipboard ist leer', vim.log.levels.WARN)
    return
  end

  text = text:gsub('“', '"'):gsub('”', '"')
  text = text:gsub('^%s*"(.-)"%s*', '%1')
  text = text:gsub('%s*%b()%s*$', '', 1)
  text = text:gsub('%s*%b()%s*$', '', 1)
  text = text:match('^%s*(.-)%s*$') or text

  M.insert_at_cursor(text)
end

function M.insert_at_cursor(text)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local new_line = line:sub(1, col) .. text .. line:sub(col + 1)
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row, col + #text })
end

function M.open_item(item)
  local uri = item.select
  if not uri and item.uri then
    local key = item.uri:match('/([^/]+)$')
    if key then
      local gid = item.uri:match('/groups/(%d+)')
      if gid then
        uri = ('zotero://select/groups/%s/items/%s'):format(gid, key)
      else
        uri = ('zotero://select/library/items/%s'):format(key)
      end
    end
  end
  if uri then
    vim.fn.system({ 'xdg-open', uri })
  end
end

vim.keymap.set('i', '<C-u>', M.cite, { desc = 'Zotero-Literatur über CAYW einfügen (Pandoc)' })
vim.keymap.set('i', '<C-z>', M.paste_zotero_highlight, { desc = 'Zotero-Highlight aus Clipboard einfügen (Pandoc)' })
vim.keymap.set('v', '<C-z>', M.paste_zotero_highlight_visual,
  { desc = 'Zotero-Highlight in Auswahl konvertieren (Pandoc)' })
vim.keymap.set('i', '<C-t>', M.paste_zotero_text, { desc = 'Zotero-Highlight als Nur-Text aus Clipboard einfügen' })

return M
