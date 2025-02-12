local setup = require("fsouza.lsp").setup
setup()

vim.api.nvim_create_user_command("LspLogs", function(opts)
  local log_message = require("fsouza.lsp.log-message")
  log_message.show_logs(opts.fargs[1])
end, { force = true, nargs = "?" })
