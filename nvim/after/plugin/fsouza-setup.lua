-- this is just a catch all that I didn't know where to put.

local function invoke_here(op)
  local dir_path = vim.fn.expand("%:p:h")
  if vim.startswith(dir_path, "/") then
    op({ cwd = dir_path })
  end
end

local function setup_fuzzy_mappings()
  local fuzzy = require("fsouza.lib.fuzzy")
  vim.keymap.set("n", "<leader>zb", fuzzy.buffers, { silent = true })
  vim.keymap.set("n", "<leader>zz", fuzzy.files, { silent = true })
  vim.keymap.set("n", "<leader>zg", fuzzy.git_files, { silent = true })
  vim.keymap.set("n", "<leader>zi", fuzzy.oldfiles, { silent = true })
  vim.keymap.set("n", "<leader>zt", fuzzy.tagstack, { silent = true })
  vim.keymap.set("n", "<leader>zp", fuzzy.git_repos, { silent = true })
  vim.keymap.set("n", "<leader>gs", fuzzy.git_status, { silent = true })
  vim.keymap.set("n", "<leader>zh", fuzzy.help_tags, { silent = true })
  vim.keymap.set("n", "<leader>zo", fuzzy.quickfix, { silent = true })
  vim.keymap.set("n", "<leader>zr", fuzzy.resume, { silent = true })
  vim.keymap.set("n", "<leader>zj", function()
    invoke_here(fuzzy.files)
  end, { silent = true })
  vim.keymap.set("n", "<leader>gg", fuzzy.live_grep)
  vim.keymap.set("n", "<leader>gj", function()
    invoke_here(fuzzy.live_grep)
  end)
  vim.keymap.set("n", "<leader>gw", function()
    fuzzy.grep(vim.fn.expand("<cword>"), "-F")
  end)
  vim.keymap.set("x", "<leader>gw", fuzzy.grep_visual)
  vim.keymap.set("n", "<leader>gl", fuzzy.grep_last)
  vim.keymap.set("n", "<leader><leader>gg", function()
    fuzzy.live_grep({ cwd = vim.uv.cwd() })
  end)
  vim.keymap.set("n", "<leader><leader>gw", function()
    fuzzy.grep(vim.fn.expand("<cword>"), "-F", vim.uv.cwd())
  end)
  vim.keymap.set("x", "<leader><leader>gw", function()
    fuzzy.grep_visual(vim.uv.cwd())
  end)
  vim.keymap.set("n", "<leader>zl", fuzzy.lines)
  vim.keymap.set("n", "<leader>zc", fuzzy.set_virtual_cwd, { silent = true })
  vim.api.nvim_create_user_command("Fcd", function(opts)
    fuzzy.set_virtual_cwd(opts.fargs[1])
  end, { force = true, complete = "dir", nargs = "?" })
end

local function setup_autofmt_commands()
  local autofmt = require("fsouza.lib.autofmt")
  vim.api.nvim_create_user_command("ToggleAutofmt", function()
    autofmt.toggle()
  end, { force = true })
  vim.api.nvim_create_user_command("ToggleGlobalAutofmt", function()
    autofmt.toggle_g()
  end, { force = true })
end

local function setup_browse_command()
  vim.api.nvim_create_user_command("OpenBrowser", function(opts)
    vim.ui.open(opts.fargs[1])
  end, { force = true, nargs = 1 })
end

local function setup_word_replace()
  vim.keymap.set("n", "<leader>x", function()
    local word = vim.fn.expand("<cword>")
    vim.api.nvim_input(":%s/\\v<lt>" .. word .. ">/" .. word .. "/g<left><left>")
  end)
end

local function setup_notif()
  local notif = require("fsouza.lib.notif")
  vim.api.nvim_create_user_command("Notifications", function()
    notif.log_messages()
  end, { force = true })
end

local function setup_yank_highlight()
  require("fsouza.lib.nvim-helpers").augroup("yank_highlight", {
    {
      events = { "TextYankPost" },
      targets = { "*" },
      callback = function()
        vim.highlight.on_yank({
          higroup = "HlYank",
          timeout = 200,
          on_macro = false,
        })
      end,
    },
  })
end

setup_autofmt_commands()
setup_browse_command()
setup_word_replace()
setup_notif()
setup_fuzzy_mappings()
setup_yank_highlight()
