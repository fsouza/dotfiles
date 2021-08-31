local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local loop = vim.loop
local helpers = require('fsouza.lib.nvim_helpers')

local langservers_skip_set = {jsonls = true; tsserver = true}

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

local function formatting_params(bufnr)
  local sts = api.nvim_buf_get_option(bufnr, 'softtabstop')
  local options = {
    tabSize = (sts > 0 and sts) or (sts < 0 and api.nvim_buf_get_option(bufnr, 'shiftwidth')) or
      api.nvim_buf_get_option(bufnr, 'tabstop');
    insertSpaces = api.nvim_buf_get_option(bufnr, 'expandtab');
  }
  return {textDocument = {uri = vim.uri_from_bufnr(bufnr)}; options = options}
end

local function fmt(client, bufnr, cb)
  local _, req_id = client.request('textDocument/formatting', formatting_params(bufnr), cb, bufnr)
  return req_id, function()
    client.cancel_request(req_id)
  end
end

local function buf_is_empty(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 2, false)
  return #lines == 0 or (#lines == 1 and lines[1] == '')
end

local function autofmt_and_write(client, bufnr)
  local enable = require('fsouza.lib.autofmt').is_enabled(bufnr)
  if not enable then
    return
  end
  if buf_is_empty(bufnr) then
    return
  end
  pcall(function()
    local changed_tick = api.nvim_buf_get_changedtick(bufnr)
    fmt(client, bufnr, function(_, _, result, _)
      if changed_tick ~= api.nvim_buf_get_changedtick(bufnr) then
        return
      end

      if result then
        api.nvim_buf_call(bufnr, function()
          helpers.rewrite_wrap(function()
            lsp.util.apply_text_edits(result, bufnr)
          end)
          vcmd('update')
        end)
      end
    end)
  end)
end

local function augroup_name(bufnr)
  return 'lsp_autofmt_' .. bufnr
end

function M.on_attach(client, bufnr)
  if should_skip_buffer(bufnr) then
    return
  end

  if should_skip_server(client.name) then
    return
  end

  helpers.augroup(augroup_name(bufnr), {
    {
      events = {'BufWritePost'};
      targets = {string.format('<buffer=%d>', bufnr)};
      command = helpers.fn_cmd(function()
        autofmt_and_write(client, bufnr)
      end);
    };
  })

  helpers.create_mappings({
    n = {
      {
        lhs = '<leader>f';
        rhs = helpers.fn_map(function()
          fmt(client, bufnr)
        end);
        opts = {silent = true};
      };
    };
  }, bufnr)
end

function M.on_detach(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    helpers.remove_mappings({n = {{lhs = '<leader>f'}}}, bufnr)
  end
  helpers.reset_augroup(augroup_name(bufnr))
end

return M
