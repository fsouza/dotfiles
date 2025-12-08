local function add_to_efm(lang_id, bufnr)
  local efm_formatters = require("fsouza.lib.efm-formatters")
  local efm_server = require("fsouza.lsp.servers.efm")

  efm_formatters.get_prettierd(function(prettierd)
    efm_formatters.get_eslintd(function(tools)
      table.insert(tools, prettierd)
      vim.schedule(function()
        efm_server.add(bufnr, lang_id, tools)
      end)
    end)
  end)
end

local function make_tss_test_check(ext)
  local pats = {
    "%." .. "spec" .. "%." .. ext,
    "%." .. "test" .. "%." .. ext,
    "/__tests__/",
  }

  return function(fname)
    for _, pat in ipairs(pats) do
      if string.find(fname, pat) then
        return true
      end
    end
    return false
  end
end

local function start_typescript_language_server(bufnr)
  local servers = require("fsouza.lsp.servers")

  servers.start({
    bufnr = bufnr,
    config = {
      name = "vtsls",
      cmd = { "vtsls", "--stdio" },
    },
    find_root_dir = function(fname)
      return servers.patterns_with_fallback({ "tsconfig.json", "package.json" }, fname)
    end,
    cb = function()
      local register_test_checker = require("fsouza.lsp.references").register_test_checker
      local exts = { "js", "jsx", "ts", "tsx" }

      for _, ext in ipairs(exts) do
        register_test_checker("." .. ext, ext, make_tss_test_check(ext))
      end
    end,
  })
end

local function start(lang_id)
  local bufnr = vim.api.nvim_get_current_buf()
  add_to_efm(lang_id, bufnr)
  start_typescript_language_server(bufnr)
end

return {
  start = start,
}
