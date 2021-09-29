local api = vim.api
local vcmd = vim.cmd
local helpers = require("fsouza.lib.nvim_helpers")

local M = {}

local debouncers = {}

local clients = {}

local ns = api.nvim_create_namespace("fsouza__code_lens")

-- stores result by bufnr & line (range.start.line)
local code_lenses = {}

local function group_by_line(codelenses, by_line)
  local to_resolve = {}
  by_line = by_line or {}
  require("fsouza.tablex").foreach(codelenses, function(codelens)
    if not codelens.command then
      table.insert(to_resolve, codelens)
    else
      local line_id = codelens.range.start.line
      local curr = by_line[line_id] or {}
      table.insert(curr, codelens)
      by_line[line_id] = curr
    end
  end)
  return by_line, to_resolve
end

local function remove_results(bufnr)
  code_lenses[bufnr] = nil
end

local function resolve_code_lenses(client, lenses, cb)
  if not client.supports_resolve then
    cb({})
    return
  end

  local resolved_lenses = {}
  local done = 0

  require("fsouza.tablex").foreach(lenses, function(lens)
    client.lsp_client.request("codeLens/resolve", lens, function(_, result)
      done = done + 1
      if result then
        table.insert(resolved_lenses, result)
      end
    end)
  end)

  local timer = vim.loop.new_timer()
  timer:start(500, 500, vim.schedule_wrap(function()
    if done == #lenses then
      timer:close()
      cb(resolved_lenses)
    end
  end))
end

local function render_virtual_text(bufnr)
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local prefix = " "
  require("fsouza.tablex").foreach(code_lenses[bufnr], function(items, line)
    local titles = require("fsouza.tablex").map(function(item)
      return item.command.title
    end, items)
    local chunks = {
      {string.format("%s%s", prefix, table.concat(titles, " | ")); "LspCodeLensVirtualText"};
    }
    api.nvim_buf_set_virtual_text(bufnr, ns, line, chunks, {})
  end)
end

local function codelenses_handler(_, codelenses, context)
  if not codelenses then
    return
  end

  local preresolved, to_resolve = group_by_line(codelenses)
  local client = clients[context.bufnr]
  if #to_resolve > 0 then
    resolve_code_lenses(client, to_resolve, function(lenses)
      code_lenses[context.bufnr] = group_by_line(lenses, preresolved)
      render_virtual_text(context.bufnr)
    end)
  else
    code_lenses[context.bufnr] = preresolved
    render_virtual_text(context.bufnr)
  end
end

local function codelenses(bufnr)
  if not clients[bufnr] then
    return
  end
  if bufnr == 0 then
    bufnr = api.nvim_get_current_buf()
  end
  local params = {textDocument = {uri = vim.uri_from_bufnr(bufnr)}}
  clients[bufnr].lsp_client.request("textDocument/codeLens", params, codelenses_handler, bufnr)
end

local function codelens(bufnr)
  local debouncer_key = bufnr
  local debounced = debouncers[debouncer_key]
  if debounced == nil then
    local interval = vim.b.lsp_codelens_debouncing_ms or 50
    debounced = require("fsouza.lib.debounce").debounce(interval, vim.schedule_wrap(codelenses))
    debouncers[debouncer_key] = debounced
    api.nvim_buf_attach(bufnr, false, {
      on_detach = function()
        debounced.stop()
        debouncers[debouncer_key] = nil
      end;
    })
  end
  debounced.call(bufnr)
end

local function execute_codelenses(bufnr, items)
  if vim.tbl_isempty(items) then
    return
  end

  local client = clients[bufnr]
  if not client then
    return
  end

  local function run(clens)
    client.lsp_client.request("workspace/executeCommand", clens.command, function(err)
      if not err then
        vcmd("checktime")
      end
    end)
  end

  local function execute_item(selected)
    if not client.supports_command then
      return
    end
    if selected.command.command ~= "" then
      run(selected)
    end
  end

  if #items > 1 then
    local popup_lines = require("fsouza.tablex")["filter-map"](function(item)
      if item.command then
        return item.command.title
      end

      return nil
    end, items)

    require("fsouza.lib.popup_picker").open(popup_lines, function(index)
      execute_item(items[index])
    end)
  else
    execute_item(items[1])
  end
end

local function execute()
  local winid = api.nvim_get_current_win()
  local bufnr = api.nvim_win_get_buf(winid)
  local cursor = api.nvim_win_get_cursor(winid)
  local line_id = cursor[1] - 1
  local buffer_results = code_lenses[bufnr]
  if not buffer_results then
    return
  end
  local line_codelenses = buffer_results[line_id]
  if not line_codelenses then
    return
  end
  execute_codelenses(bufnr, line_codelenses)
end

local function augroup_name(bufnr)
  return "lsp_codelens_" .. bufnr
end

function M.on_attach(opts)
  local bufnr = opts.bufnr
  local client = opts.client
  clients[bufnr] = {
    lsp_client = client;
    supports_resolve = opts.can_resolve;
    supports_command = opts.supports_command;
    mapping = opts.mapping;
  }
  vim.schedule(function()
    codelens(bufnr)
  end)

  local augroup_id = augroup_name(bufnr)
  helpers.augroup(augroup_id, {
    {
      events = {"InsertLeave"; "BufWritePost"};
      targets = {string.format("<buffer=%d>", bufnr)};
      command = helpers["fn-cmd"](function()
        codelens(bufnr)
      end);
    };
  })

  vim.schedule(function()
    require("fsouza.lsp.buf_diagnostic").register_hook(augroup_id, function()
      codelens(bufnr)
    end)
    api.nvim_buf_attach(bufnr, false, {
      on_detach = function()
        M.on_detach(bufnr)
      end;
    })
  end)

  if opts.mapping then
    helpers["create-mappings"]({
      n = {{lhs = opts.mapping; rhs = helpers["fn-map"](execute); {silent = true}}};
    }, bufnr)
  end
end

function M.on_detach(bufnr)
  local client_opts = clients[bufnr]

  if api.nvim_buf_is_valid(bufnr) then
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    if client_opts and client_opts.mapping then
      helpers["remove-mappings"]({n = {{lhs = client_opts.mapping}}}, bufnr)
    end
  end

  clients[bufnr] = nil
  local augroup_id = augroup_name(bufnr)
  helpers.reset_augroup(augroup_id)
  require("fsouza.lsp.buf_diagnostic").unregister_hook(augroup_id)
  remove_results(bufnr)
  clients[bufnr] = nil

end

return M
