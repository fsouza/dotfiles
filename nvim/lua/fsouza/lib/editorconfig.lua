local function parse_output(data)
  local result = {}
  for _, line in ipairs(vim.split(data, "\n")) do
    local parts = vim.split(line, "=")
    if #parts == 2 then
      result[parts[1]] = parts[2]
    end
  end
  return result
end

local function get_vim_fenc(v)
  if v == "utf-8" then
    return v, false
  elseif v == "latin1" then
    return v, false
  elseif v == "utf-16be" then
    return v, true
  elseif v == "utf-16le" then
    return v, true
  else
    return "utf-8", true
  end
end

local function handle_charset(vim_opts, v)
  local fenc, bomb = get_vim_fenc(v)
  vim_opts.fileencoding = fenc
  vim_opts.bomb = bomb
end

local function handle_eol(vim_opts, v)
  if v == "crlf" then
    vim_opts.fileformat = "dos"
  elseif v == "cr" then
    vim_opts.fileformat = "mac"
  else
    vim_opts.fileformat = "unix"
  end
end

local function handle_indent_style(vim_opts, v)
  vim_opts.expandtab = (v == "space")
end

local function handle_insert_final_line(vim_opts, v)
  vim_opts.fixendofline = (v == "true")
  vim_opts.endofline = (v == "true")
end

local function handle_indent_size(vim_opts, v, opts)
  local indent_size = (opts.indent_style == "space") and tonumber(v) or 0
  vim_opts.shiftwidth = indent_size
  vim_opts.softtabstop = indent_size
end

local function trim_whitespace(opts)
  local buf = opts.buf
  if not vim.b[buf] or vim.b[buf].keep_whitespace == nil then
    vim.api.nvim_buf_call(buf, function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      pcall(function()
        vim.cmd.substitute({
          args = {"/\\v\\s+$//"},
          range = {1, vim.api.nvim_buf_line_count(0)},
          mods = {silent = true, keeppatterns = true}
        })
      end)
      vim.api.nvim_win_set_cursor(0, cursor)
    end)
  end
end

local function handle_whitespaces(bufnr, v)
  local commands = {}
  if v == "true" then
    table.insert(commands, {
      events = {"BufWritePre"},
      targets = {string.format("<buffer=%d>", bufnr)},
      callback = trim_whitespace
    })
  end
  
  if vim.api.nvim_buf_is_valid(bufnr) then
    local augroup = require("fsouza.lib.nvim-helpers").augroup
    augroup("editorconfig_trim_trailing_whitespace_" .. bufnr, commands)
  end
end

local function set_opts(bufnr, opts)
  local vim_opts = {tabstop = 8}
  
  for k, v in pairs(opts) do
    if k == "charset" then
      handle_charset(vim_opts, v)
    elseif k == "end_of_line" then
      handle_eol(vim_opts, v)
    elseif k == "indent_style" then
      handle_indent_style(vim_opts, v)
    elseif k == "insert_final_line" or k == "insert_final_newline" then
      handle_insert_final_line(vim_opts, v)
    elseif k == "indent_size" then
      handle_indent_size(vim_opts, v, opts)
    elseif k == "trim_trailing_whitespace" then
      vim.schedule(function() handle_whitespaces(bufnr, v) end)
    end
  end
  
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modifiable then
      for option_name, value in pairs(vim_opts) do
        vim.bo[bufnr][option_name] = value
      end
    end
  end)
end

local function modify_filename_if_needed(name, bufnr)
  local ft_map = {
    python = ".py",
    sh = ".sh",
    ruby = ".rb",
    query = ".scm",
    bash = ".sh",
    zsh = ".zsh",
    javascript = ".js"
  }
  
  local path = require("fsouza.lib.path")
  local _, ext = path.splitext(name)
  
  if ext ~= "" then
    return name
  else
    local ft = vim.bo[bufnr].filetype
    local new_ext = ft_map[ft]
    if new_ext then
      return name .. new_ext
    else
      return name
    end
  end
end

local function set_config(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  
  if vim.bo[bufnr].modifiable and not vim.bo[bufnr].readonly and 
     filename ~= "" and string.find(filename, "^%a+://") == nil then
     
    local path = require("fsouza.lib.path")
    filename = path.abspath(filename)
    filename = modify_filename_if_needed(filename, bufnr)
    
    vim.system(
      {"editorconfig", filename},
      nil,
      vim.schedule_wrap(function(result)
        if result.code == 0 then
          set_opts(bufnr, parse_output(result.stdout))
        else
          vim.notify(string.format("failed to run editorconfig: %s", vim.inspect(result)))
        end
      end)
    )
  end
end

local function setup()
  local augroup = require("fsouza.lib.nvim-helpers").augroup
  augroup("editorconfig", {
    {
      events = {"BufNewFile", "BufReadPost", "BufFilePost", "FileType"},
      targets = {"*"},
      callback = function(opts) set_config(opts.buf) end
    }
  })
end

return {
  setup = setup
}