local function from_shebang(path, bufnr)
  local pattern_mapping = {
    python = "python",
    bash = "bash",
    zsh = "zsh",
    ["/sh"] = "sh",
    ruby = "ruby",
    ["env sh"] = "sh"
  }

  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, true)[1]
  local _, _, prog = string.find(first_line, "^#!(.+)")

  if prog then
    for pattern, ft in pairs(pattern_mapping) do
      if string.find(prog, pattern) then
        return ft
      end
    end
  end

  return nil
end

local function from_shellcheck_annotation(path, bufnr)
  -- look at up to 10 lines. Can bump this if I run into cases where the
  -- annotation is not within the first 10 lines.
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)
  local pat = "^#%s+shellcheck%s+.*shell=([%w_]+)"

  for _, line in ipairs(lines) do
    local shell = string.match(line, pat)
    if shell then
      return shell
    end
  end

  return nil
end

local function from_current_shell()
  local shell = os.getenv("SHELL")
  if shell then
    return vim.fs.basename(shell)
  end
  return nil
end

local fts = {
  extension = {
    sh = function(path, bufnr)
      return from_shellcheck_annotation(path, bufnr) or
             from_shebang(path, bufnr) or
             from_current_shell()
    end,
    [""] = from_shebang
  },
  filename = {
    ["go.mod"] = "gomod",
    ["setup.cfg"] = "pysetupcfg",
    ["Brewfile"] = "ruby"
  }
}

vim.filetype.add(fts)
