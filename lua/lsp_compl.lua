local api = vim.api
local lsp = vim.lsp
local M = {}
local SNIPPET = 2

local client_settings = {}
local completion_ctx
completion_ctx = {
  expand_snippet = false,
  isIncomplete = false,
  suppress_completeDone = false,
  cursor = nil,

  pending_requests = {},
  cancel_pending = function()
    for _, cancel in pairs(completion_ctx.pending_requests) do
      cancel()
    end
    completion_ctx.pending_requests = {}
  end,
  reset = function()
    -- Cursor is not reset here, it needs to survive a `CompleteDone` event
    completion_ctx.expand_snippet = false
    completion_ctx.isIncomplete = false
    completion_ctx.suppress_completeDone = false
    completion_ctx.cancel_pending()
  end
}

local function get_documentation(item)
  local docs = item.documentation
  if type(docs) == 'string' then
    return docs
  end
  if type(docs) == 'table' and type(docs.value) == 'string' then
    return docs.value
  end
  return ''
end

local function get_detail(item)
  local max_width = 10

  if not item.detail then
    return ''
  end

  if #item.detail <= max_width + 3 then
    return item.detail
  end

  return string.format("%s...", string.sub(item.detail, 1, max_width))
end

function M.text_document_completion_list_to_complete_items(result, prefix, fuzzy)
  local items = lsp.util.extract_completion_items(result)
  if #items == 0 then
    return {}
  end
  local matches = {}
  for _, item in pairs(items) do
    local kind = lsp.protocol.CompletionItemKind[item.kind] or ''
    local word
    if kind == 'Snippet' then
      word = item.label
    elseif item.insertTextFormat == SNIPPET then
      if item.textEdit then
        word = item.insertText or item.textEdit.newText
      elseif item.insertText then
        if #item.label < #item.insertText then
          word = item.label
        else
          word = item.insertText
        end
      else
        word = item.label
      end
    else
      word = (item.textEdit and item.textEdit.newText) or item.insertText or item.label
    end
    if fuzzy or vim.startswith(word, prefix) then
      table.insert(matches, {
        word = word,
        abbr = item.label,
        kind = kind,
        menu = get_detail(item),
        icase = 1,
        dup = 1,
        empty = 1,
        equal = fuzzy and 1 or 0,
        user_data = item
      })
    end
  end
  table.sort(matches, function(a, b)
    return (a.user_data.sortText or a.user_data.label) < (b.user_data.sortText or b.user_data.label)
  end)
  return matches
end

local function adjust_start_col(lnum, line, items, encoding)
  -- vim.fn.complete takes a startbyte and selecting a completion entry will
  -- replace anything between the startbyte and the current cursor position
  -- with the completion item's word
  --
  -- `col` is derived using `vim.fn.match(line_to_cursor, '\\k*$') + 1`
  -- Which works for most cases to find the word boundary, but the language
  -- server may work with a different boundary.
  --
  -- Luckily, the LSP response contains an (optional) `textEdit` with range,
  -- which indicates which boundary the language server used.
  --
  -- Concrete example, in Lua where there is currently a known mismatch:
  --
  -- require('plenary.asy|
  --         ▲       ▲   ▲
  --         │       │   │
  --         │       │   └── cursor_pos: 20
  --         │       └────── col: 17
  --         └────────────── textEdit.range.start.character: 9
  --                                 .newText = 'plenary.async'
  --
  -- Caveat:
  --  - textEdit.range can (in theory) be different *per* item.
  --  - range.start.character is (usually) a UTF-16 offset
  --
  -- Approach:
  --  - Use textEdit.range.start.character *only* if *all* items contain the same value
  --    Otherwise we'd have to normalize the `word` value.
  --
  local min_start_char = nil

  for _, item in pairs(items) do
    if item.textEdit and item.textEdit.range.start.line == lnum - 1 then
      if min_start_char and min_start_char ~= item.textEdit.range.start.character then
        return nil
      end
      min_start_char = item.textEdit.range.start.character
    end
  end
  if min_start_char then
    if encoding == 'utf-8' then
      return min_start_char + 1
    else
      return vim.str_byteindex(line, min_start_char, encoding == 'utf-16') + 1
    end
  else
    return nil
  end
end


function M.trigger_completion(client, bufnr)
  completion_ctx.cancel_pending()
  local lnum, cursor_pos = unpack(api.nvim_win_get_cursor(0))
  local line = api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, cursor_pos)
  local col = vim.fn.match(line_to_cursor, '\\k*$') + 1
  local params = lsp.util.make_position_params()
  local _, req_id = client.request('textDocument/completion', params, function(err, result, ctx)
    local client_id = ctx.client_id
    completion_ctx.pending_requests = {}
    assert(not err, vim.inspect(err))
    if not result then
      print('No completion result')
      return
    end
    completion_ctx.isIncomplete = result.isIncomplete
    local line_changed = api.nvim_win_get_cursor(0)[1] ~= lnum
    local mode = api.nvim_get_mode()['mode']
    if line_changed or not (mode == 'i' or mode == 'ic') then
      return
    end
    local client = vim.lsp.get_client_by_id(client_id)
    local items = lsp.util.extract_completion_items(result)
    local encoding = client and client.offset_encoding or 'utf-16'
    local startbyte = adjust_start_col(lnum, line, items, encoding) or col
    local opts = client_settings[client_id] or {}
    local prefix = line:sub(startbyte, cursor_pos)
    local matches = M.text_document_completion_list_to_complete_items(
      result,
      prefix,
      opts.server_side_fuzzy_completion
    )
    vim.fn.complete(startbyte, matches)
  end, bufnr)
  if req_id then
    table.insert(completion_ctx.pending_requests, function ()
      client.cancel_request(req_id)
    end)
  end
end


function M._InsertLeave()
  completion_ctx.cursor = nil
  completion_ctx.reset()
end


local function apply_text_edits(bufnr, lnum, text_edits, client)
  -- Text edit in the same line would mess with the cursor position
  local edits = vim.tbl_filter(
    function(x) return x.range.start.line ~= lnum end,
    text_edits or {}
  )
  lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
end


M.expand_snippet = function(snippet)
  require('luasnip').lsp_expand(snippet)
end


local function apply_snippet(item, suffix)
  if item.textEdit then
    M.expand_snippet(item.textEdit.newText .. suffix)
  elseif item.insertText then
    M.expand_snippet(item.insertText .. suffix)
  end
end


function M._CompleteDone(client_id, bufnr)
  if completion_ctx.suppress_completeDone then
    completion_ctx.suppress_completeDone = false
    return
  end
  local completed_item = api.nvim_get_vvar('completed_item')
  if not completed_item or not completed_item.user_data then
    completion_ctx.reset()
    return
  end
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  lnum = lnum - 1
  local item = completed_item.user_data
  local expand_snippet = item.insertTextFormat == SNIPPET and completion_ctx.expand_snippet
  local suffix = nil
  if expand_snippet then
    -- Remove the already inserted word
    local start_char = col - #completed_item.word
    local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1]
    suffix = line:sub(col + 1)
    api.nvim_buf_set_text(bufnr, lnum, start_char, lnum, #line, {''})
  end
  completion_ctx.reset()
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then
    return
  end
  local resolve_edits = (client.server_capabilities.completionProvider or {}).resolveProvider
  if item.additionalTextEdits then
    if expand_snippet then
      apply_snippet(item, suffix)
    end
    apply_text_edits(bufnr, lnum, item.additionalTextEdits, client)
  elseif resolve_edits and type(item) == "table" then
    local _, req_id = client.request('completionItem/resolve', item, function(err, result)
      completion_ctx.pending_requests = {}
      assert(not err, vim.inspect(err))
      if expand_snippet then
        apply_snippet(item, suffix)
      end
      apply_text_edits(bufnr, lnum, result.additionalTextEdits, client)
    end, bufnr)
    if req_id then
      table.insert(completion_ctx.pending_requests, function()
        client.cancel_request(req_id)
      end)
    end
  elseif expand_snippet then
    apply_snippet(item, suffix)
  end
end


function M.detach(client_id, bufnr)
  vim.cmd(string.format('augroup lsp_compl_%d_%d', client_id, bufnr))
  vim.cmd('au!')
  vim.cmd('augroup end')
  vim.cmd(string.format('augroup! lsp_compl_%d_%d', client_id, bufnr))
  client_settings[client_id] = nil
end


function M.attach(client, bufnr, opts)
  opts = opts or {}
  client_settings[client.id] = opts
  vim.cmd(string.format('augroup lsp_compl_%d_%d', client.id, bufnr))
  vim.cmd('au!')
  vim.cmd(string.format("autocmd InsertLeave <buffer=%d> lua require'lsp_compl'._InsertLeave()", bufnr))
  vim.cmd(string.format(
    "autocmd CompleteDone <buffer=%d> lua require'lsp_compl'._CompleteDone(%d, %d)",
    bufnr,
    client.id,
    bufnr
  ))
  vim.cmd('augroup end')
end

return M
