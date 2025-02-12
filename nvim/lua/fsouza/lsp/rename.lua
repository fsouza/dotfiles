local function rename(client, bufnr)
  local function perform_rename(placeholder)
    placeholder = placeholder or vim.fn.expand("<cword>")
    local new_name = vim.fn.input("New name: ", placeholder)

    if new_name and new_name ~= "" then
      local params = vim.lsp.util.make_position_params()
      params.newName = new_name
      client:request("textDocument/rename", params)
    end
  end

  local function prepare_rename_cb(_, result)
    if result and result.placeholder then
      perform_rename(result.placeholder)
    elseif
      result
      and result.start
      and result.start.line
      and result["end"]
      and result["end"].line
      and result.start.line == result["end"].line
    then
      local line = vim.api.nvim_buf_get_lines(bufnr, result.start.line, result.start.line + 1, true)[1]

      local pos_first_char = result.start.character + 1
      local pos_last_char = result["end"].character
      local placeholder = string.sub(line, pos_first_char, pos_last_char)

      perform_rename(placeholder)
    else
      vim.api.nvim_echo({ { "can't rename at current position", "WarningMsg" } }, true, {})
    end
  end

  local method = "textDocument/prepareRename"
  if client:supports_method(method) then
    client:request(method, vim.lsp.util.make_position_params(), prepare_rename_cb, bufnr)
  else
    perform_rename()
  end
end

return {
  rename = rename,
}
