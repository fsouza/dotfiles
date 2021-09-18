local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local langservers_skip_set = {jsonls = true; tsserver = true}

local langservers_org_imports = {gopls = true}

local updates = {}

local function set_last_update(bufnr)
  updates[bufnr] = os.clock()
end

local function get_last_update(bufnr)
  return updates[bufnr]
end

local function should_skip_buffer(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local prefix = vfn.getcwd()
  if not vim.endswith(prefix, '/') then
    prefix = prefix .. '/'
  end
  local skip = not vim.startswith(file_path, prefix)
  if skip then
    vim.notify(string.format([[[DEBUG] skipping %s because it's not in %s]], file_path, prefix))
  end
  return skip
end

local function should_skip_server(server_name)
  return langservers_skip_set[server_name] ~= nil
end

local function should_organize_imports(server_name)
  return langservers_org_imports[server_name] ~= nil
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

local function organize_imports_and_write(client, bufnr)
  local changed_tick = api.nvim_buf_get_changedtick(bufnr)
  local params = vim.lsp.util.make_given_range_params({1; 1},
                                                      {api.nvim_buf_line_count(bufnr); 2147483647})
  params.context = {diagnostics = vim.diagnostic.get(bufnr, {namespace = client.id})}

  client.request('textDocument/codeAction', params, function(_, actions)
    if changed_tick ~= api.nvim_buf_get_changedtick(bufnr) then
      return
    end

    if not actions or vim.tbl_isempty(actions) then
      return
    end

    local _, code_action = require('fsouza.tablex').find_if(actions, function(action)
      if action.kind == 'source.organizeImports' then
        return action
      else
        return false
      end
    end)

    if code_action and code_action.edit then
      api.nvim_buf_call(bufnr, function()
        vim.lsp.util.apply_workspace_edit(code_action.edit)
        vcmd('update')
      end)
    end
  end, bufnr)
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
    fmt(client, bufnr, function(_, result)
      if changed_tick ~= api.nvim_buf_get_changedtick(bufnr) then
        return
      end

      if result then
        api.nvim_buf_call(bufnr, function()
          lsp.util.apply_text_edits(result, bufnr)

          local last_update = get_last_update(bufnr)
          if last_update and os.clock() - last_update < 0.01 then
            vcmd('noau update')
          else
            vcmd('update')
            set_last_update(bufnr)
          end
        end)

        if should_organize_imports(client.name) then
          organize_imports_and_write(client, bufnr)
        end
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
