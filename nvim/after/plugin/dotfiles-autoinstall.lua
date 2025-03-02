local augroup = require("fsouza.lib.nvim-helpers").augroup
local should_clear_qf = false

local function handle_result(result)
  if result.code == 0 then
    if should_clear_qf then
      should_clear_qf = false
      vim.fn.setqflist({})
      vim.cmd.cclose()
    end
    vim.notify("Successfully compiled")
  else
    local qf = require("fsouza.lib.qf")
    if qf.set_from_contents(result.stderr, { open = true }) then
      vim.cmd.wincmd("p")
      should_clear_qf = true
    end
  end
end

local function make(opts)
  if not vim.g.fennel_ks then
    vim.system({ "make", "-C", _G.dotfiles_dir, "install" }, {
      env = {
        NVIM_CONFIG_DIR = vim.fn.stdpath("config"),
        NVIM_STATE_DIR = vim.fn.stdpath("state"),
      },
    }, vim.schedule_wrap(handle_result))
  end
end

augroup("fsouza__autoinstall-dotfiles", {
  {
    events = { "BufWritePost" },
    targets = {
      _G.dotfiles_dir .. "/hammerspoon/*.lua",
      _G.dotfiles_dir .. "/nvim/*.lua",
      _G.dotfiles_dir .. "/nvim/*.scm",
      _G.dotfiles_dir .. "/nvim/*.vim",
    },
    callback = make,
  },
})
