local function should_use_ts(node)
  if node == nil then
    return false
  end

  local node_type = node:type()
  local node_types = {
    -- generic
    "local_function",
    "function_declaration",
    "method_declaration",
    "type_spec",
    "assignment",
    -- typescript
    "class",
    "function",
    "type_alias_declaration",
    "interface_declaration",
    "method_definition",
    "variable_declarator",
    "public_field_definition",
    -- python
    "class_definition",
    "function_definition",
    -- go
    "var_spec",
    -- ocaml
    "let_binding",
    "value_definition",
    "type_definition",
    -- java
    "class_declaration",
  }

  for _, type_name in ipairs(node_types) do
    if type_name == node_type then
      return true
    end
  end

  return false
end

local function normalize_loc(loc)
  if not loc.uri then
    if loc.targetUri then
      loc.uri = loc.targetUri
    end
    if loc.targetRange then
      loc.range = loc.targetRange
    end
  end
  return loc
end

local function ts_range(current_buf, loc)
  loc = normalize_loc(loc)

  if not loc.uri then
    return loc
  end

  local parsers = require("nvim-treesitter.parsers")
  local filetype = vim.bo[current_buf].filetype
  local lang = parsers.ft_to_lang(filetype)

  if not lang or lang == "" or not parsers.has_parser(lang) then
    return loc
  end

  local bufnr = vim.uri_to_bufnr(loc.uri)
  local start_pos = loc.range.start
  local end_pos = loc.range["end"]

  vim.bo[bufnr].buflisted = true
  vim.bo[bufnr].filetype = filetype

  local parser = vim.treesitter.get_parser(bufnr, lang)
  local _, tree = next(parser:trees())

  if not tree then
    return loc
  end

  local root = tree:root()
  local node = root:named_descendant_for_range(start_pos.line, start_pos.character, end_pos.line, end_pos.character)

  local parent_node = node:parent()
  local ts_node

  if should_use_ts(parent_node) then
    ts_node = parent_node
  elseif should_use_ts(node) then
    ts_node = node
  end

  if ts_node then
    local sl, sc, el, ec = ts_node:range()
    loc.range.start.line = sl
    loc.range.start.character = sc
    loc.range["end"].line = el
    loc.range["end"].character = ec
  end

  return loc
end

local function peek_location_callback(_, result, context)
  if result then
    local loc
    if vim.islist(result) then
      loc = result[1]
    else
      loc = result
    end

    loc = ts_range(context.bufnr, loc)
    local _, winid = vim.lsp.util.preview_location(loc)

    if winid then
      local popup = require("fsouza.lib.popup")
      popup.stylize(winid)
    end
  end
end

local function make_lsp_loc_action(method)
  return function()
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, method, params, peek_location_callback)
  end
end

return {
  preview_definition = make_lsp_loc_action("textDocument/definition"),
  preview_declaration = make_lsp_loc_action("textDocument/declaration"),
  preview_implementation = make_lsp_loc_action("textDocument/implementation"),
  preview_type_definition = make_lsp_loc_action("textDocument/typeDefinition"),
}
