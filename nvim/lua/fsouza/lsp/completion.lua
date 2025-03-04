-- used to store information about ongoing completion, gets reset everytime we
-- exit "completion mode".
local state = { ["inflight-requests"] = {}, ["rendered-docs"] = {} }

local winid = nil
local doc_bufnr = nil

local function cr_key_for_comp_info(comp_info)
  if comp_info.mode == "" then
    return "<cr>"
  elseif comp_info.pum_visible == 1 and comp_info.selected == -1 then
    return "<c-e><cr>"
  else
    return "<cr>"
  end
end

local function item_documentation(item)
  if type(item.documentation) == "table" then
    return item.documentation
  else
    return { kind = "plaintext", value = vim.trim(item.documentation or "") }
  end
end

local function popup_contents(item)
  local item_key = vim.inspect(item)
  local docs = state["rendered-docs"][item_key]

  if docs then
    return docs
  else
    local doc_lines = {}
    local detail = item.detail or ""
    detail = vim.trim(detail)
    local documentation = item_documentation(item)

    if detail ~= "" then
      table.insert(doc_lines, { kind = "plaintext", value = detail })
    end

    if documentation.value ~= "" then
      table.insert(doc_lines, documentation.value)
    end

    local docs = vim.lsp.util.convert_input_to_markdown_lines(doc_lines)
    state["rendered-docs"][item_key] = docs
    return docs
  end
end

local function calc_max_width(max_width, starting_pos, right)
  local cols = vim.o.columns
  local available_space

  if right then
    available_space = cols - starting_pos - 2
  else
    available_space = starting_pos - 2
  end

  return math.min(max_width, available_space)
end

local function valid_winid()
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function valid_doc_bufnr()
  return doc_bufnr and vim.api.nvim_buf_is_valid(doc_bufnr)
end

local function show_or_update_popup(contents)
  if vim.fn.pumvisible() ~= 0 then
    local pum_pos = vim.fn.pum_getpos()
    local row = pum_pos.row
    local col = pum_pos.col
    local width = pum_pos.width
    local scrollbar = pum_pos.scrollbar and 1 or 0

    local end_col = col + width + scrollbar
    local max_width = calc_max_width(100, end_col, true)
    local right = max_width > 25

    if not right then
      max_width = calc_max_width(100, col, false)
    end

    local left_col = right and end_col or nil
    local right_col = (not right and col) or nil

    local p = require("fsouza.lib.popup")
    local popup_winid, popup_bufnr = p.open({
      lines = contents,
      enter = false,
      type_name = "completion-doc",
      markdown = true,
      row = row,
      col = left_col,
      right_col = right_col,
      relative = "editor",
      max_width = max_width,
      update_if_exists = true,
      wrap = true,
    })

    winid = popup_winid
    doc_bufnr = popup_bufnr
  end
end

local function augroup_name(bufnr)
  return string.format("fsouza-completion-%d", bufnr)
end

local function close()
  if valid_winid() then
    vim.api.nvim_win_close(winid, false)
  end

  if valid_doc_bufnr() then
    vim.api.nvim_buf_delete(doc_bufnr, { force = true })
  end

  winid = nil
  doc_bufnr = nil
end

local function render_docs(item)
  local docs = popup_contents(item)
  if #docs > 0 then
    vim.schedule(function()
      show_or_update_popup(docs)
    end)
  end
end

local function reset_state()
  close()

  for req_id, client in pairs(state["inflight-requests"]) do
    vim.schedule(function()
      client:cancel_request(req_id)
    end)
  end

  state["inflight-requests"] = {}
  state["rendered-docs"] = {}
end

local function do_CompleteChanged(bufnr, user_data)
  if user_data.item then
    local lsp_compl = require("lsp_compl")
    lsp_compl.resolve_item(user_data, render_docs)
  else
    close()
  end
end

local function on_CompleteChanged(bufnr)
  local completed_item = vim.v.event.completed_item or {}
  local user_data = completed_item.user_data or {}

  vim.schedule(function()
    do_CompleteChanged(bufnr, user_data)
  end)
end

local function do_InsertLeave(bufnr)
  reset_state()
  local nvim_helpers = require("fsouza.lib.nvim-helpers")
  nvim_helpers.reset_augroup(augroup_name(bufnr))
end

local function on_InsertLeave(bufnr)
  vim.schedule(function()
    do_InsertLeave(bufnr)
  end)
end

local function on_attach(bufnr)
  local lsp_compl = require("lsp_compl")

  local function complete()
    local augroup = require("fsouza.lib.nvim-helpers").augroup

    augroup(augroup_name(bufnr), {
      {
        events = { "CompleteChanged" },
        targets = { string.format("<buffer=%d>", bufnr) },
        callback = function()
          on_CompleteChanged(bufnr)
        end,
      },
      {
        events = { "CompleteDone" },
        targets = { string.format("<buffer=%d>", bufnr) },
        once = true,
        callback = reset_state,
      },
      {
        events = { "InsertLeave" },
        targets = { string.format("<buffer=%d>", bufnr) },
        once = true,
        callback = function()
          on_InsertLeave(bufnr)
        end,
      },
    })

    lsp_compl.trigger_completion(bufnr)
    return ""
  end

  lsp_compl.attach(bufnr)

  vim.keymap.set("i", "<c-x><c-o>", complete, { remap = false, buffer = bufnr })

  vim.keymap.set("i", "<cr>", function()
    return cr_key_for_comp_info(vim.fn.complete_info())
  end, { remap = false, buffer = bufnr, expr = true })
end

return {
  on_attach = on_attach,
}
