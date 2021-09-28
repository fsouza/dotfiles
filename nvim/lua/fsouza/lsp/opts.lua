local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local api = vim.api

local setup_symbols_outline = helpers.once(function()
  require('symbols-outline').setup({
    highlight_hovered_item = false;
    auto_preview = false;
    keymaps = {toggle_preview = {'<leader>i'}; close = {'<leader>v'}};
    symbols = {
      File = {icon = '>'; hl = 'TSURI'};
      Module = {icon = 'Ｍ'; hl = 'TSNamespace'};
      Namespace = {icon = '>'; hl = 'TSNamespace'};
      Package = {icon = '>'; hl = 'TSNamespace'};
      Class = {icon = '𝓒'; hl = 'TSType'};
      Method = {icon = 'ƒ'; hl = 'TSMethod'};
      Property = {icon = 'ƒ'; hl = 'TSMethod'};
      Field = {icon = '>'; hl = 'TSField'};
      Constructor = {icon = 'ƒ'; hl = 'TSConstructor'};
      Enum = {icon = 'ℰ'; hl = 'TSType'};
      Interface = {icon = 'ﰮ'; hl = 'TSType'};
      Function = {icon = 'ƒ'; hl = 'TSFunction'};
      Variable = {icon = '>'; hl = 'TSConstant'};
      Constant = {icon = '>'; hl = 'TSConstant'};
      String = {icon = '𝓐'; hl = 'TSString'};
      Number = {icon = '#'; hl = 'TSNumber'};
      Boolean = {icon = '⊨'; hl = 'TSBoolean'};
      Array = {icon = 'Ａ'; hl = 'TSConstant'};
      Object = {icon = '⦿'; hl = 'TSType'};
      Key = {icon = '🔐'; hl = 'TSType'};
      Null = {icon = 'NULL'; hl = 'TSType'};
      EnumMember = {icon = '>'; hl = 'TSField'};
      Struct = {icon = '𝓢'; hl = 'TSType'};
      Event = {icon = '>'; hl = 'TSType'};
      Operator = {icon = '+'; hl = 'TSOperator'};
      TypeParameter = {icon = '𝙏'; hl = 'TSParameter'};
    };
  })
end)

local cmds = {
  show_line_diagnostics = helpers.fn_map(function()
    vim.diagnostic.show_line_diagnostics({focusable = false})
  end);
  list_file_diagnostics = helpers.fn_map(function()
    require('fsouza.lsp.diagnostics').list_file_diagnostics()
  end);
  list_workspace_diagnostics = helpers.fn_map(function()
    require('fsouza.lsp.diagnostics').list_workspace_diagnostics()
  end);
  fuzzy_workspace_diagnostics = helpers.fn_map(function()
    require('fsouza.plugin.fuzzy').lsp_workspace_diagnostics()
  end);
  clear_buffer_diagnostics = helpers.fn_map(function()
    require('fsouza.lsp.buf_diagnostic').buf_clear_all_diagnostics()
  end);
  goto_next_diagnostic = helpers.fn_map(function()
    vim.diagnostic.goto_next({popup_opts = {focusable = false}})
  end);
  goto_prev_diagnostic = helpers.fn_map(function()
    vim.diagnostic.goto_prev({popup_opts = {focusable = false}})
  end);
  rename = helpers.fn_map(function()
    vim.lsp.buf.rename()
  end);
  code_action = helpers.fn_map(function()
    require('fsouza.lsp.code_action').code_action()
  end);
  visual_code_action = helpers.vfn_map(function()
    require('fsouza.lsp.code_action').visual_code_action()
  end);
  goto_declaration = helpers.fn_map(function()
    vim.lsp.buf.declaration()
  end);
  preview_declaration = helpers.fn_map(function()
    require('fsouza.lsp.locations').preview_declaration()
  end);
  highlight_references = helpers.fn_map(function()
    vim.lsp.buf.document_highlight()
  end);
  clear_references = helpers.fn_map(function()
    vim.lsp.buf.clear_references()
  end);
  list_document_symbols = helpers.fn_map(function()
    require('fsouza.plugin.fuzzy').lsp_document_symbols()
  end);
  find_references = helpers.fn_map(function()
    vim.lsp.buf.references()
  end);
  goto_definition = helpers.fn_map(function()
    vim.lsp.buf.definition()
  end);
  preview_definition = helpers.fn_map(function()
    require('fsouza.lsp.locations').preview_definition()
  end);
  display_information = helpers.fn_map(function()
    vim.lsp.buf.hover()
  end);
  goto_implementation = helpers.fn_map(function()
    vim.lsp.buf.implementation()
  end);
  preview_implementation = helpers.fn_map(function()
    require('fsouza.lsp.locations').preview_implementation()
  end);
  display_signature_help = helpers.fn_map(function()
    vim.lsp.buf.signature_help()
  end);
  goto_type_definition = helpers.fn_map(function()
    vim.lsp.buf.type_definition()
  end);
  preview_type_definition = helpers.fn_map(function()
    require('fsouza.lsp.locations').preview_type_definition()
  end);
  query_workspace_symbols = helpers.fn_map(function()
    local query = vim.fn.input('query：')
    if query ~= '' then
      require('fsouza.plugin.fuzzy').lsp_workspace_symbols({query = query})
    end
  end);
  symbols_outline = helpers.fn_map(function()
    setup_symbols_outline()
    require('symbols-outline').toggle_outline()
  end);
}

local function attached(bufnr, client)
  local register_detach = function(cb)
    require('fsouza.lsp.detach').register(bufnr, cb)
  end

  vim.schedule(function()
    local mappings = {
      n = {
        {lhs = '<leader>l'; rhs = cmds.show_line_diagnostics; opts = {silent = true}};
        {lhs = '<leader>df'; rhs = cmds.list_file_diagnostics; opts = {silent = true}};
        {lhs = '<leader>dw'; rhs = cmds.list_workspace_diagnostics; opts = {silent = true}};
        {lhs = '<leader>dd'; rhs = cmds.fuzzy_workspace_diagnostics; opts = {silent = true}};
        {lhs = '<leader>cl'; rhs = cmds.clear_buffer_diagnostics; opts = {silent = true}};
        {lhs = '<c-n>'; rhs = cmds.goto_next_diagnostic; opts = {silent = true}};
        {lhs = '<c-p>'; rhs = cmds.goto_prev_diagnostic; opts = {silent = true}};
      };
      i = {};
      x = {};
    }

    if client.resolved_capabilities.text_document_did_change then
      require('fsouza.lsp.shell_post').on_attach({bufnr = bufnr; client = client})
      register_detach(require('fsouza.lsp.shell_post').on_detach)
    end

    if client.resolved_capabilities.completion then
      require('fsouza.lsp.completion').on_attach(bufnr, {'nvim_lsp'; 'buffer'})
      register_detach(require('fsouza.lsp.completion').on_detach)
    end

    if client.resolved_capabilities.rename ~= nil and client.resolved_capabilities.rename ~= false then
      table.insert(mappings.n, {lhs = '<leader>r'; rhs = cmds.rename; opts = {silent = true}})
    end

    if client.resolved_capabilities.code_action then
      table.insert(mappings.n, {lhs = '<leader>cc'; rhs = cmds.code_action; opts = {silent = true}})
      table.insert(mappings.x,
                   {lhs = '<leader>cc'; rhs = cmds.visual_code_action; opts = {silent = true}})
    end

    if client.resolved_capabilities.declaration then
      table.insert(mappings.n,
                   {lhs = '<leader>gy'; rhs = cmds.goto_declaration; opts = {silent = true}})
      table.insert(mappings.n,
                   {lhs = '<leader>py'; rhs = cmds.preview_declaration; opts = {silent = true}})
    end

    if client.resolved_capabilities.document_formatting then
      require('fsouza.lsp.formatting').on_attach(client, bufnr)
      register_detach(require('fsouza.lsp.formatting').on_detach)
    end

    if client.resolved_capabilities.document_highlight then
      table.insert(mappings.n,
                   {lhs = '<leader>s'; rhs = cmds.highlight_references; opts = {silent = true}})
      table.insert(mappings.n,
                   {lhs = '<leader>S'; rhs = cmds.clear_references; opts = {silent = true}})
    end

    if client.resolved_capabilities.document_symbol then
      table.insert(mappings.n,
                   {lhs = '<leader>t'; rhs = cmds.list_document_symbols; opts = {silent = true}})
      table.insert(mappings.n,
                   {lhs = '<leader>v'; rhs = cmds.symbols_outline; opts = {silent = true}})
    end

    if client.resolved_capabilities.find_references then
      table.insert(mappings.n,
                   {lhs = '<leader>q'; rhs = cmds.find_references; opts = {silent = true}})
    end

    if client.resolved_capabilities.goto_definition then
      table.insert(mappings.n,
                   {lhs = '<leader>gd'; rhs = cmds.goto_definition; opts = {silent = true}})
      table.insert(mappings.n,
                   {lhs = '<leader>pd'; rhs = cmds.preview_definition; opts = {silent = true}})
    end

    if client.resolved_capabilities.hover then
      table.insert(mappings.n,
                   {lhs = '<leader>i'; rhs = cmds.display_information; opts = {silent = true}})
    end

    if client.resolved_capabilities.implementation then
      table.insert(mappings.n,
                   {lhs = '<leader>gi'; rhs = cmds.goto_implementation; opts = {silent = true}})
      table.insert(mappings.n,
                   {lhs = '<leader>pi'; rhs = cmds.preview_implementation; opts = {silent = true}})
    end

    if client.resolved_capabilities.signature_help then
      table.insert(mappings.i,
                   {lhs = '<c-k>'; rhs = cmds.display_signature_help; opts = {silent = true}})
    end

    if client.resolved_capabilities.type_definition then
      table.insert(mappings.n,
                   {lhs = '<leader>gt'; rhs = cmds.goto_type_definition; opts = {silent = true}})
      table.insert(mappings.n, {
        lhs = '<leader>pt';
        rhs = cmds.preview_type_definition;
        opts = {silent = true};
      })
    end

    if client.resolved_capabilities.workspace_symbol then
      table.insert(mappings.n,
                   {lhs = '<leader>T'; rhs = cmds.query_workspace_symbols; opts = {silent = true}})
    end

    if client.resolved_capabilities.code_lens then
      require('fsouza.lsp.code_lens').on_attach({
        bufnr = bufnr;
        client = client;
        mapping = '<leader><cr>';
        can_resolve = client.resolved_capabilities.code_lens_resolve;
        supports_command = client.resolved_capabilities.execute_command;
      })
      register_detach(require('fsouza.lsp.code_lens').on_detach)
    end

    require('fsouza.lsp.progress').on_attach()

    vim.schedule(function()
      helpers.create_mappings(mappings, bufnr)
      register_detach(function()
        helpers.remove_mappings(mappings, bufnr)
      end)
    end)
  end)
end

local function on_attach(client, bufnr)
  if bufnr == 0 or bufnr == nil then
    bufnr = api.nvim_get_current_buf()
  end

  attached(bufnr, client)
end

function M.with_defaults(opts)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  capabilities.workspace.executeCommand = {dynamicRegistration = false}

  return vim.tbl_extend('force', {
    handlers = require('fsouza.lsp.handlers');
    on_attach = on_attach;
    capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities, {
      snippetSupport = false;
      preselectSupport = false;
      commitCharactersSupport = false;
    });
    root_dir = function()
      return vim.fn.getcwd()
    end;
  }, opts);
end

M.root_pattern_with_fallback = function(...)
  local find_root = require('lspconfig').util.root_pattern(...)
  return function(startpath)
    return find_root(startpath) or vim.fn.getcwd()
  end
end

return M
