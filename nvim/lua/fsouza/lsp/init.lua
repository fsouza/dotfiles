local disabled_methods = {
  efm = {["textDocument/definition"] = true},
  ["ruff-server"] = {["textDocument/hover"] = true}
}

local function patch_server_capabilities(client)
  local capabilities_to_disable = {gopls = {"semanticTokensProvider"}}
  local caps = capabilities_to_disable[client.name] or {}
  
  for _, cap in ipairs(caps) do
    client.server_capabilities[cap] = nil
  end
end

local function patch_supports_method(client)
  local supports_method = client.supports_method
  client.supports_method = function(client, method)
    local disabled = disabled_methods[client.name] and 
                    disabled_methods[client.name][method] or false
    return (not disabled) and supports_method(client, method)
  end
end

-- for each method, have a function that returns [ACTION args]
--
-- where [ACTION args] can be either:
--
--  - [ATTACH attach-fn]
--  - [MAPPINGS [{: mode : lhs : rhs}]]
local method_handlers = (function()
  local fuzzy = require("fsouza.lib.fuzzy")
  local locations = require("fsouza.lsp.locations")
  
  return {
    ["callHierarchy/incomingCalls"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>lc", rhs = fuzzy.lsp_incoming_calls}
      }}
    end,
    
    ["callHierarchy/outgoingCalls"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>lC", rhs = fuzzy.lsp_outgoing_calls}
      }}
    end,
    
    ["textDocument/codeAction"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>cc", rhs = vim.lsp.buf.code_action},
        {mode = "x", lhs = "<leader>cc", rhs = vim.lsp.buf.code_action}
      }}
    end,
    
    ["textDocument/codeLens"] = function()
      return {"ATTACH", function(bufnr)
        local codelens = require("fsouza.lsp.codelens")
        codelens.on_attach({bufnr = bufnr, mapping = "<leader><cr>"})
      end}
    end,
    
    ["textDocument/completion"] = function()
      local completion = require("fsouza.lsp.completion")
      return {"ATTACH", completion.on_attach}
    end,
    
    ["textDocument/declaration"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>gy", rhs = function()
          vim.lsp.buf.declaration({on_list = fuzzy.lsp_on_list})
        end},
        {mode = "n", lhs = "<leader>py", rhs = locations.preview_declaration}
      }}
    end,
    
    ["textDocument/definition"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>gd", rhs = function()
          vim.lsp.buf.definition({on_list = fuzzy.lsp_on_list})
        end},
        {mode = "n", lhs = "<leader>pd", rhs = locations.preview_definition}
      }}
    end,
    
    ["textDocument/documentHighlight"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>s", rhs = function()
          vim.lsp.util.buf_clear_references()
          vim.lsp.buf.document_highlight()
        end},
        {mode = "n", lhs = "<leader>S", rhs = vim.lsp.buf.clear_references}
      }}
    end,
    
    ["textDocument/documentSymbol"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>t", rhs = fuzzy.lsp_document_symbols}
      }}
    end,
    
    ["textDocument/formatting"] = function(_, bufnr)
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>f", rhs = function()
          local formatting = require("fsouza.lsp.formatting")
          formatting.fmt(bufnr)
        end}
      }}
    end,
    
    ["textDocument/hover"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>i", rhs = vim.lsp.buf.hover}
      }}
    end,
    
    ["textDocument/implementation"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>gi", rhs = function()
          vim.lsp.buf.implementation({on_list = fuzzy.lsp_on_list})
        end},
        {mode = "n", lhs = "<leader>pi", rhs = locations.preview_implementation}
      }}
    end,
    
    ["textDocument/references"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>q", rhs = function()
          vim.lsp.buf.references(nil, {
            on_list = function(...)
              local references = require("fsouza.lsp.references")
              references.on_list(...)
            end
          })
        end}
      }}
    end,
    
    ["textDocument/rename"] = function(client, bufnr)
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>r", rhs = function()
          local rename = require("fsouza.lsp.rename")
          rename.rename(client, bufnr)
        end}
      }}
    end,
    
    ["textDocument/signatureHelp"] = function()
      return {"MAPPINGS", {
        {mode = "i", lhs = "<c-k>", rhs = vim.lsp.buf.signature_help}
      }}
    end,
    
    ["textDocument/typeDefinition"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>gt", rhs = function()
          vim.lsp.buf.type_definition({on_list = fuzzy.lsp_on_list})
        end},
        {mode = "n", lhs = "<leader>pt", rhs = locations.preview_type_definition}
      }}
    end,
    
    ["workspace/symbol"] = function()
      return {"MAPPINGS", {
        {mode = "n", lhs = "<leader>T", rhs = function()
          local query = vim.fn.input("query：")
          if query ~= "" then
            fuzzy.lsp_workspace_symbols({lsp_query = query})
          end
        end}
      }}
    end
  }
end)()

local function register_method(name, client, bufnr)
  local function handle_attach(attach_fn)
    attach_fn(bufnr)
  end

  local function handle_mappings(mappings)
    for _, mapping in ipairs(mappings) do
      vim.keymap.set(mapping.mode, mapping.lhs, mapping.rhs, 
                    {silent = true, buffer = bufnr})
    end
  end

  local handler = method_handlers[name]
  if handler and client:supports_method(name, {bufnr = bufnr}) then
    local result = handler(client, bufnr)
    if result[1] == "ATTACH" then
      handle_attach(result[2])
    elseif result[1] == "MAPPINGS" then
      handle_mappings(result[2])
    end
  end
end

local function diag_open_float(scope)
  vim.schedule(function()
    local _, winid = vim.diagnostic.open_float({
      source = "if_many",
      scope = scope,
      focusable = false,
      border = "solid"
    })
    
    if winid then
      local p = require("fsouza.lib.popup")
      p.stylize(winid)
    end
  end)
end

local function diag_jump(jump_fn)
  jump_fn({float = false})
  diag_open_float("cursor")
end

local function lsp_attach(opts)
  local bufnr = opts.buf
  local client_id = opts.data.client_id
  local client = vim.lsp.get_client_by_id(client_id)
  
  local shell_post = require("fsouza.lsp.shell-post")
  local diagnostics = require("fsouza.lsp.diagnostics")
  local fuzzy = require("fsouza.lib.fuzzy")
  
  local mappings = {
    {lhs = "<leader>ll", rhs = function() diag_open_float("line") end},
    {lhs = "<leader>df", rhs = diagnostics.list_file_diagnostics},
    {lhs = "<leader>dw", rhs = diagnostics.list_workspace_diagnostics},
    {lhs = "<leader>dd", rhs = fuzzy.lsp_workspace_diagnostics},
    {lhs = "<c-n>", rhs = function() diag_jump(vim.diagnostic.goto_next) end},
    {lhs = "<c-p>", rhs = function() diag_jump(vim.diagnostic.goto_prev) end}
  }
  
  patch_server_capabilities(client)
  patch_supports_method(client)
  shell_post.on_attach(bufnr)
  
  for method, _ in pairs(method_handlers) do
    register_method(method, client, bufnr)
  end
  
  diagnostics.on_attach()
  vim.bo[bufnr].formatexpr = nil
  
  for _, mapping in ipairs(mappings) do
    vim.keymap.set("n", mapping.lhs, mapping.rhs, 
                  {silent = true, buffer = bufnr})
  end
end

local function config_log()
  local level = vim.env.NVIM_DEBUG and "trace" or "error"
  local lsp_log = require("vim.lsp.log")
  lsp_log.set_level(level)
  lsp_log.set_format_func(vim.inspect)
end

local function config_diagnostics()
  local empty_s = setmetatable({}, {__index = function() return "" end})
  
  vim.diagnostic.config({
    underline = true,
    virtual_text = false,
    update_in_insert = false,
    signs = {
      text = empty_s,
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint"
      }
    }
  })
end

local function set_defaults(client, bufnr)
  if client:supports_method("textDocument/diagnostic") then
    vim.lsp.diagnostic._enable(bufnr)
  end
end

local function setup()
  config_diagnostics()
  config_log()
  vim.lsp._set_defaults = set_defaults
  
  local augroup = require("fsouza.lib.nvim-helpers").augroup
  augroup("fsouza__LspAttach", {
    {events = {"LspAttach"}, callback = lsp_attach}
  })
end

return {
  setup = setup,
  register_method = register_method
}