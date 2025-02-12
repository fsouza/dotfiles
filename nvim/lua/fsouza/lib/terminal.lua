-- maps number to a terminal, where a terminal is a table with the following
-- shape: { bufnr: ..., job-id: ... }
local terminals = {}

local function create_terminal(term_id)
  local filetype = "fsouza-terminal"
  local bufnr = vim.api.nvim_create_buf(true, false)

  vim.bo[bufnr].filetype = filetype

  vim.api.nvim_buf_call(bufnr, function()
    local job_id = vim.fn.termopen(string.format("%s;#fsouza_term;%s", vim.o.shell, term_id), {
      detach = false,
      on_exit = function()
        terminals[term_id] = nil
      end,
    })
    terminals[term_id] = { bufnr = bufnr, job_id = job_id }
  end)

  return terminals[term_id]
end

local function get_term(term_id)
  local term = terminals[term_id]
  if term and vim.api.nvim_buf_is_valid(term.bufnr) then
    return term
  else
    terminals[term_id] = nil
    return nil
  end
end

local function ensure_term(term_id)
  local term = get_term(term_id)
  if term then
    return term
  else
    return create_terminal(term_id)
  end
end

local function open(term_id)
  local term = ensure_term(term_id)
  vim.api.nvim_set_current_buf(term.bufnr)
end

local function run(term_id, cmd)
  local term = ensure_term(term_id)
  vim.fn.chansend(term.job_id, { cmd, "" })
end

local function cr()
  local cfile = vim.fn.expand("<cfile>")
  if vim.fn.filereadable(cfile) == 1 then
    vim.cmd.only({ mods = { silent = true } })
    vim.cmd.wincmd("F")
  end
end

return {
  open = open,
  cr = cr,
  run = run,
}
