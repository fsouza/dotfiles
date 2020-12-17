local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local loop = vim.loop
local helpers = require('fsouza.lib.nvim_helpers')

local fmt_clients = {}

local langservers_skip_set = {tsserver = true}

local function should_skip_buffer(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local prefix = loop.cwd()
  if not vim.endswith(prefix, '/') then
    prefix = prefix .. '/'
  end
  local skip = not vim.startswith(file_path, prefix)
  if skip then
    print(string.format([[[DEBUG] skipping %s because it's not in %s]], file_path, prefix))
  end
  return skip
end

local function should_skip_server(server_name)
  return langservers_skip_set[server_name] ~= nil
end

function M.register_client(client, bufnr)
  if should_skip_buffer(bufnr) then
    return
  end

  if should_skip_server(client.name) then
    return
  end

  if fmt_clients[bufnr] and fmt_clients[bufnr].id ~= client.id then
    print(string.format([[[DEBUG] overriding client %s with %s]], fmt_clients[bufnr].name,
                        client.name))
  end
  fmt_clients[bufnr] = client

  helpers.augroup('lsp_autofmt_' .. bufnr, {
    {
      events = {'BufWritePost'};
      targets = {'<buffer>'};
      command = string.format([[lua require('fsouza.lsp.formatting').autofmt_and_write(%d)]], bufnr);
    };
  })

  api.nvim_buf_set_keymap(bufnr, 'n', '<leader>f',
                          helpers.cmd_map([[lua require('fsouza.lsp.formatting').fmt()]]),
                          {silent = true})
end

local function formatting_params(bufnr)
  local sts = api.nvim_buf_get_option(bufnr, 'softtabstop')
  local options = {
    tabSize = (sts > 0 and sts) or (sts < 0 and api.nvim_buf_get_option(bufnr, 'shiftwidth')) or
      api.nvim_buf_get_option(bufnr, 'tabstop');
    insertSpaces = api.nvim_buf_get_option(bufnr, 'expandtab');
  }
  return {textDocument = {uri = vim.uri_from_bufnr(bufnr)}; options = options}
end

local function apply_edits(result, bufnr)
  local curbuf = api.nvim_get_current_buf()
  if curbuf ~= bufnr then
    return
  end

  helpers.rewrite_wrap(function()
    lsp.util.apply_text_edits(result, bufnr)
  end)
end

local function fmt(bufnr, cb)
  local client = fmt_clients[bufnr]
  if not client then
    error(string.format('cannot format the buffer %d, no lsp client registered', bufnr))
  end

  local _, req_id = client.request('textDocument/formatting', formatting_params(bufnr), cb, bufnr)
  return req_id, function()
    client.cancel_request(req_id)
  end
end

function M.fmt()
  fmt(api.nvim_get_current_buf(), nil)
end

function M.fmt_sync(bufnr, timeout_ms)
  local result
  local _, cancel = fmt(bufnr, function(_, _, result_, _)
    result = result_
  end)

  vim.wait(timeout_ms or 200, function()
    return result ~= nil
  end, 10)

  if not result then
    cancel()
    return
  end
  apply_edits(result, bufnr)
end

function M.autofmt(bufnr)
  local enable, timeout_ms = require('fsouza.lib.autofmt').config()
  if enable then
    pcall(function()
      M.fmt_sync(bufnr, timeout_ms)
    end)
  end
end

function M.autofmt_and_write(bufnr)
  local enable, _ = require('fsouza.lib.autofmt').config()
  if not enable then
    return
  end
  pcall(function()
    fmt(bufnr, function(_, _, result, _)
      local curr_buf = api.nvim_get_current_buf()
      if curr_buf ~= bufnr or api.nvim_get_mode().mode ~= 'n' then
        return
      end
      if result then
        apply_edits(result, bufnr)
        vcmd('noautocmd update')
      end
    end)
  end)
end

return M
