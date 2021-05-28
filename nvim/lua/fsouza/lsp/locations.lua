local M = {}

local lsp = vim.lsp
local lsp_util = require('vim.lsp.util')
local parsers = require('nvim-treesitter.parsers')

local function should_use_ts(node)
  if node == nil then
    return false
  end

  local node_type = node:type()

  -- TODO: this should use ts queries
  local node_types = {
    -- generic
    'local_function';
    'function_declaration';
    'method_declaration';
    'type_spec';
    'assignment';

    -- typescript
    'class';
    'function';
    'type_alias_declaration';
    'interface_declaration';
    'method_definition';
    'variable_declarator';
    'public_field_definition';

    -- python
    'class_definition';
    'function_definition';

    -- go
    'var_spec';
  }
  for _, t in pairs(node_types) do
    if node_type == t then
      return true
    end
  end
  return false
end

local function normalize_loc(loc)
  if loc.uri then
    return loc
  end

  if loc.targetUri then
    loc.uri = loc.targetUri

    if loc.targetRange then
      loc.range = loc.targetRange
    end
  end

  return loc
end

local function ts_range(loc)
  loc = normalize_loc(loc)
  if not loc.uri then
    return loc
  end

  local lang = parsers.ft_to_lang(vim.o.filetype)
  if not lang or lang == '' then
    return loc
  end
  if not parsers.has_parser(lang) then
    return loc
  end

  local bufnr = vim.uri_to_bufnr(loc.uri)
  vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', vim.o.filetype)

  local start_pos = loc.range.start
  local end_pos = loc.range['end']

  local parser = vim.treesitter.get_parser(bufnr, lang)
  local _, t = next(parser:trees())
  if not t then
    return loc
  end
  local root = t:root()
  local node = root:named_descendant_for_range(start_pos.line, start_pos.character, end_pos.line,
                                               end_pos.character)

  local parent_node = node:parent()
  if should_use_ts(parent_node) then
    local sl, sc, el, ec = parent_node:range()
    loc.range.start.line = sl
    loc.range.start.character = sc
    loc.range['end'].line = el
    loc.range['end'].character = ec
  end
  return loc
end

local function peek_location_callback(_, _, result)
  if not result or vim.tbl_isempty(result) then
    return
  end
  local loc = ts_range(result[1])
  local _, win_id = lsp_util.preview_location(loc)
  require('fsouza.color').set_popup_winid(win_id)
end

local function make_lsp_loc_action(method)
  return function()
    local params = lsp_util.make_position_params()
    lsp.buf_request(0, method, params, peek_location_callback)
  end
end

M.preview_definition = make_lsp_loc_action('textDocument/definition')

M.preview_declaration = make_lsp_loc_action('textDocument/declaration')

M.preview_implementation = make_lsp_loc_action('textDocument/implementation')

M.preview_type_definition = make_lsp_loc_action('textDocument/typeDefinition')

return M
