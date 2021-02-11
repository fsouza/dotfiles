local M = {}

local api = vim.api

local function attached(bufnr, client)
  local helpers = require('fsouza.lib.nvim_helpers')
  vim.schedule(function()
    local mappings = {
      n = {
        {
          lhs = '<leader>l';
          rhs = helpers.fn_map(vim.lsp.diagnostic.show_line_diagnostics);
          opts = {silent = true};
        };
        {
          lhs = '<leader>df';
          rhs = helpers.fn_map(require('fsouza.lsp.diagnostics').list_file_diagnostics);
          opts = {silent = true};
        };
        {
          lhs = '<leader>dw';
          rhs = helpers.fn_map(require('fsouza.lsp.diagnostics').list_workspace_diagnostics);
          opts = {silent = true};
        };
        {
          lhs = '<leader>cl';
          rhs = helpers.fn_map(require('fsouza.lsp.buf_diagnostic').buf_clear_all_diagnostics);
          opts = {silent = true};
        };
        {lhs = '<c-n>'; rhs = helpers.fn_map(vim.lsp.diagnostic.goto_next); opts = {silent = true}};
        {lhs = '<c-p>'; rhs = helpers.fn_map(vim.lsp.diagnostic.goto_prev); opts = {silent = true}};
      };
      i = {};
      x = {};
    }

    if client.resolved_capabilities.text_document_did_change then
      require('fsouza.lsp.shell_post').on_attach({bufnr = bufnr; client = client})
    end

    if client.resolved_capabilities.completion then
      require('fsouza.lsp.completion').on_attach(bufnr)
    end

    if client.resolved_capabilities.rename ~= nil and client.resolved_capabilities.rename ~= false then
      table.insert(mappings.n, {
        lhs = '<leader>r';
        rhs = helpers.fn_map(vim.lsp.buf.rename);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.code_action then
      table.insert(mappings.n, {
        lhs = '<leader>cc';
        rhs = helpers.fn_map(require('fsouza.lsp.code_action').code_action);
        opts = {silent = true};
      })
      table.insert(mappings.x, {
        lhs = '<leader>cc';
        rhs = helpers.vfn_map(require('fsouza.lsp.code_action').visual_code_action);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.declaration then
      table.insert(mappings.n, {
        lhs = '<leader>gy';
        rhs = helpers.fn_map(vim.lsp.buf.declaration);
        opts = {silent = true};
      })
      table.insert(mappings.n, {
        lhs = '<leader>py';
        rhs = helpers.fn_map(require('fsouza.lsp.locations').preview_declaration);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.document_formatting then
      require('fsouza.lsp.formatting').on_attach(client, bufnr)
    end

    if client.resolved_capabilities.document_highlight then
      table.insert(mappings.n, {
        lhs = '<leader>s';
        rhs = helpers.fn_map(vim.lsp.buf.document_highlight);
        opts = {silent = true};
      })
      table.insert(mappings.n, {
        lhs = '<leader>S';
        rhs = helpers.fn_map(vim.lsp.buf.clear_references);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.document_symbol then
      table.insert(mappings.n, {
        lhs = '<leader>t';
        rhs = helpers.fn_map(vim.lsp.buf.document_symbol);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.find_references then
      table.insert(mappings.n, {
        lhs = '<leader>q';
        rhs = helpers.fn_map(vim.lsp.buf.references);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.goto_definition then
      table.insert(mappings.n, {
        lhs = '<leader>gd';
        rhs = helpers.fn_map(vim.lsp.buf.definition);
        opts = {silent = true};
      })
      table.insert(mappings.n, {
        lhs = '<leader>pd';
        rhs = helpers.fn_map(require('fsouza.lsp.locations').preview_definition);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.hover then
      table.insert(mappings.n, {
        lhs = '<leader>i';
        rhs = helpers.fn_map(vim.lsp.buf.hover);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.implementation then
      table.insert(mappings.n, {
        lhs = '<leader>gi';
        rhs = helpers.fn_map(vim.lsp.buf.implementation);
        opts = {silent = true};
      })
      table.insert(mappings.n, {
        lhs = '<leader>pi';
        rhs = helpers.fn_map(require('fsouza.lsp.locations').preview_implementation);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.signature_help then
      table.insert(mappings.i, {
        lhs = '<c-k>';
        rhs = helpers.fn_map(vim.lsp.buf.signature_help);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.type_definition then
      table.insert(mappings.n, {
        lhs = '<leader>gt';
        rhs = helpers.fn_map(vim.lsp.buf.type_definition);
        opts = {silent = true};
      })
      table.insert(mappings.n, {
        lhs = '<leader>pt';
        rhs = helpers.fn_map(require('fsouza.lsp.locations').preview_type_definition);
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.workspace_symbol then
      table.insert(mappings.n, {
        lhs = '<leader>T';
        rhs = helpers.fn_map(vim.lsp.buf.workspace_symbol);
        opts = {silent = true};
      })
    end

    -- should use resolved_capabilities here, but this is not supported by nvim
    -- yet.
    if client.server_capabilities.codeLensProvider then
      require('fsouza.lsp.code_lens').on_attach({
        bufnr = bufnr;
        client = client;
        mapping = '<leader><cr>';
        can_resolve = client.server_capabilities.codeLensProvider.resolveProvider == true;
        supports_command = client.resolved_capabilities.execute_command;
      })
    end

    require('fsouza.lsp.progress').on_attach()

    vim.schedule(function()
      helpers.create_mappings(mappings, bufnr)
    end)
  end)
end

local function on_attach(client, bufnr)
  local all_clients = vim.lsp.get_active_clients()
  for _, c in pairs(all_clients) do
    if c.id == client.id then
      client = c
    end
  end

  if bufnr == 0 or bufnr == nil then
    bufnr = api.nvim_get_current_buf()
  end

  attached(bufnr, client)
end

function M.with_defaults(opts)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  return vim.tbl_extend('keep', opts, {
    handlers = require('fsouza.lsp.handlers');
    on_attach = on_attach;
    capabilities = capabilities;
  });
end

M.root_pattern_with_fallback = function(...)
  local find_root = require('lspconfig').util.root_pattern(...)
  return function(startpath)
    return find_root(startpath) or vim.loop.cwd()
  end
end

return M
