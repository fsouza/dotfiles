-- maps bufnr to client
local buffer_clients = {}

local langservers_org_imports_set = { gopls = true }

local function should_organize_imports(client_name)
  return client_name and langservers_org_imports_set[client_name]
end

local function with_diagnostics(client, bufnr, cb)
  local function call_cb()
    local diagnostics = vim.diagnostic.get(bufnr, { namespace = client.id })
    cb(diagnostics)
  end

  if client:supports_method("textDocument/diagnostic") then
    local textDocument = vim.lsp.util.make_text_document_params(bufnr)
    client:request("textDocument/diagnostic", { textDocument = textDocument }, call_cb)
  else
    call_cb()
  end
end

local function execute(client, action, cb, resolved)
  if action.edit or type(action.command) == "table" then
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    if type(action.command) == "table" then
      vim.lsp.buf.execute_command(action.command)
    end
    cb()
  elseif not resolved then
    client:request("codeAction/resolve", action, function(_, resolved_action)
      if resolved_action then
        execute(client, resolved_action, cb, true)
      end
    end)
  elseif action.command and action.arguments then
    vim.lsp.buf.execute_command(action)
    cb()
  end
end

local function organize_imports_and_write(client, bufnr, kind)
  local changed_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.range.start = { line = 0, character = 0 }
  params.range["end"] = {
    line = vim.api.nvim_buf_line_count(bufnr) - 1,
    character = 0,
  }

  with_diagnostics(client, bufnr, function(diagnostics)
    params.context = { diagnostics = diagnostics }

    client:request("textDocument/codeAction", params, function(_, actions)
      if actions and changed_tick == vim.api.nvim_buf_get_changedtick(bufnr) and not vim.tbl_isempty(actions) then
        local code_action = nil
        for _, action in ipairs(actions) do
          if action.kind == kind then
            code_action = action
            break
          end
        end

        if code_action then
          execute(client, code_action, function()
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd.update()
            end)
          end)
        end
      end
    end)
  end)
end

local function handle(bufnr)
  local client_data = buffer_clients[bufnr]
  if not client_data then
    return
  end

  local client_id = client_data.client_id
  local kind = client_data.kind
  local client = vim.lsp.get_client_by_id(client_id)

  if client then
    organize_imports_and_write(client, bufnr, kind)
  else
    buffer_clients[bufnr] = nil
  end
end

local setup = (function()
  local nvim_helpers = require("fsouza.lib.nvim-helpers")
  return nvim_helpers.once(function()
    nvim_helpers.augroup("fsouza__autocodeaction", {
      {
        events = { "User" },
        targets = { "fsouza-LSP-autoformatted" },
        callback = function(opts)
          local bufnr = opts.data.bufnr
          if buffer_clients[bufnr] then
            handle(bufnr)
          end
        end,
      },
    })
  end)
end)()

local function attach(bufnr, client_id, kind)
  setup()
  buffer_clients[bufnr] = { client_id = client_id, kind = kind }
end

return {
  attach = attach,
}
