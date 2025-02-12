local function is_go_test(fname)
  return vim.endswith(fname, "_test.go")
end

local function setup()
  local bufnr = vim.api.nvim_get_current_buf()
  local servers = require("fsouza.lsp.servers")

  servers.start({
    config = {
      name = "gopls",
      cmd = { vim.fs.joinpath(_G.cache_dir, "langservers", "bin", "gopls") },
      init_options = {
        deepCompletion = false,
        staticcheck = true,
        analyses = {
          fillreturns = true,
          nonewvars = true,
          undeclaredname = true,
          unusedparams = true,
          ST1000 = false,
        },
        linksInHover = false,
        codelenses = { vendor = false },
        gofumpt = true,
        usePlaceholders = false,
        experimentalPostfixCompletions = false,
        completeFunctionCalls = false,
      },
    },
    find_root_dir = function(fname)
      return servers.patterns_with_fallback({ "go.mod" }, fname)
    end,
    bufnr = bufnr,
    opts = {
      autofmt = true,
      auto_action = "source.organizeImports",
    },
    cb = function()
      local references = require("fsouza.lsp.references")
      references.register_test_checker(".go", "go", is_go_test)
    end,
  })
end

return {
  setup = setup,
}
