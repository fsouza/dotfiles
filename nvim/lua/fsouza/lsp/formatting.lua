local buffer_registry = {}

local function should_skip_buffer(bufnr)
  local path = require("fsouza.lib.path")
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  file_path = path.abspath(file_path)
  return not path.isrel(file_path)
end

local function formatting_params(bufnr)
  local et = vim.bo[bufnr].expandtab
  local tab_size = et and vim.bo[bufnr].softtabstop or vim.bo[bufnr].tabstop
  local opts = { tabSize = tab_size, insertSpaces = et }

  return {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    options = opts,
  }
end

local function find_client(bufnr)
  local client_data = buffer_registry[bufnr] or {}
  local client_name = client_data.client_name or ""

  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = client_name })
  if clients[1] then
    return clients[1]
  end

  clients = vim.lsp.get_clients({ bufnr = bufnr, name = "efm" })
  if clients[1] then
    return clients[1]
  end

  clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/formatting",
  })
  return clients[1]
end

local function fmt(bufnr, client, callback)
  client = client or find_client(bufnr)

  if client then
    local _, req_id = client:request("textDocument/formatting", formatting_params(bufnr), callback, bufnr)

    return req_id, function()
      client:cancel_request(req_id)
    end
  end
end

local function augroup_name(bufnr)
  return "lsp_autofmt_" .. bufnr
end

local function detach(bufnr)
  local nvim_helpers = require("fsouza.lib.nvim-helpers")
  nvim_helpers.reset_augroup(augroup_name(bufnr))
  buffer_registry[bufnr] = nil
end

local function autofmt_and_write(bufnr, client_id)
  local function do_autocmd()
    vim.api.nvim_exec_autocmds({ "User" }, { pattern = "fsouza-LSP-autoformatted", data = { bufnr = bufnr } })
  end

  local autofmt = require("fsouza.lib.autofmt")
  local enabled = autofmt.is_enabled(bufnr)
  local client = vim.lsp.get_client_by_id(client_id)

  if client then
    if enabled then
      pcall(function()
        local changed_tick = vim.api.nvim_buf_get_changedtick(bufnr)

        fmt(bufnr, client, function(_, result)
          if vim.api.nvim_buf_is_valid(bufnr) and changed_tick == vim.api.nvim_buf_get_changedtick(bufnr) then
            if result then
              vim.api.nvim_buf_call(bufnr, function()
                local helpers = require("fsouza.lib.nvim-helpers")
                local hash = helpers.hash_buffer(bufnr)

                helpers.rewrite_wrap(function()
                  vim.lsp.util.apply_text_edits(result, bufnr, client.offset_encoding)
                end)

                if changed_tick ~= vim.api.nvim_buf_get_changedtick(bufnr) then
                  local new_hash = helpers.hash_buffer(bufnr)
                  local noautocmd = new_hash == hash
                  vim.cmd.update({ mods = { noautocmd = noautocmd } })
                end
              end)
            end
          end
        end)

        do_autocmd()
      end)
    end
  else
    -- client is gone, let's detach
    detach(bufnr)
    do_autocmd()
  end
end

local function attach(bufnr, client_id, priority)
  local client = vim.lsp.get_client_by_id(client_id)
  local current_data = buffer_registry[bufnr] or { priority = 0 }
  local current_priority = current_data.priority
  priority = priority or 1

  if client and not should_skip_buffer(bufnr) and priority > current_priority then
    local augroup = require("fsouza.lib.nvim-helpers").augroup
    augroup(augroup_name(bufnr), {
      {
        events = { "BufWritePost" },
        targets = { string.format("<buffer=%d>", bufnr) },
        callback = function()
          autofmt_and_write(bufnr, client_id)
        end,
      },
    })

    buffer_registry[bufnr] = {
      client_name = client.name,
      priority = priority,
    }
  end
end

return {
  attach = attach,
  fmt = fmt,
}
