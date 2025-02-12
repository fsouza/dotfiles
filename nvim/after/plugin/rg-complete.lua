local function process_stdout(content)
  local lines = vim.split(content, "\n", { plain = true, trimempty = true })
  local uniq_lines = {}

  for _, line in ipairs(lines) do
    local trimmed_line = vim.trim(line)
    uniq_lines[trimmed_line] = true
  end

  return vim.tbl_keys(uniq_lines)
end

local function find_pos(line)
  return string.find(line, "[^%s]")
end

local function complete()
  local current_line = vim.api.nvim_get_current_line()
  local compl_pos = find_pos(current_line)
  current_line = vim.trim(current_line)

  if current_line then
    vim.system(
      {
        "rg",
        "--case-sensitive",
        "--fixed-strings",
        "--no-line-number",
        "--no-filename",
        "--no-heading",
        "--hidden",
        "--",
        current_line,
        ".",
      },
      nil,
      vim.schedule_wrap(function(result)
        if result.code == 0 then
          vim.fn.complete(compl_pos, process_stdout(result.stdout))
        end
      end)
    )
  end

  return ""
end

local keybind = "<c-x><c-n>"
vim.keymap.set("i", keybind, complete, { remap = false })
