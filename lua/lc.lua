local M = {}

function M.setup()
  local lsp = require "nvim_lsp"

  lsp.bashls.setup {
    cmd = { "vim-nodels", "bash-language-server", "start" };
  }

  lsp.cssls.setup {
    cmd = { "vim-nodels", "css-laguageserver", "--stdio" };
  }

  lsp.gopls.setup {
    init_options = {
      deepCompletion = false;
      staticcheck = true;
      analyses = {
        unusedparams = true;
        ST1000 = false;
      };
    };
  }

  lsp.html.setup {
    cmd = { "vim-nodels", "html-langserver", "--stdio" };
  }

  lsp.jsonls.setup {
    cmd = { "vim-nodels", "vscode-json-languageserver", "--stdio" };
  }

  lsp.ocamllsp.setup {
    cmd = { "vim-ocaml-lsp" };
  }

  lsp.pyls.setup {
    cmd = { "python", "-m", "pyls" };
    settings = {
      pyls = {
        plugins = {
          jedi_completion = {
            enabled = true;
            fuzzy = true;
            include_params = false;
          };
        };
      };
    };
  }

  lsp.rust_analyzer.setup{}

  lsp.tsserver.setup {
    cmd = { "vim-nodels", "typescript-language-server", "--stdio" };
  }

  lsp.vimls.setup {
    cmd = { "vim-nodels",  "vim-language-server", "--stdio" };
  }

  lsp.yamlls.setup {
    cmd = { "vim-nodels", "yaml-language-server", "--stdio" };
  }
end

-- TODO: nvim-lsp will eventually support this, so once the pending PR is
-- merged, we should delete this code.
--
-- We also need something better than pcall (perhaps only set the autocmd on
-- servers that have formatting capabilities).
local function formatting_params(options)
  local sts = vim.bo.softtabstop
  options = vim.tbl_extend("keep", options or {}, {
    tabSize = (sts > 0 and sts) or (sts < 0 and vim.bo.shiftwidth) or vim.bo.tabstop;
    insertSpaces = vim.bo.expandtab;
  })
  return {
    textDocument = { uri = vim.uri_from_bufnr(0) };
    options = options;
  }
end

function M.formatting_sync(options, timeout_ms)
  pcall(function ()
    local params = formatting_params(options)
    local result = vim.lsp.buf_request_sync(0, "textDocument/formatting", params, timeout_ms)
    if not result then return end
    result = result[1].result
    vim.lsp.util.apply_text_edits(result)
  end)
end

function M.nvim_lsp_enabled_for_current_ft()
  local clients = vim.lsp.buf_get_clients()
  local length = 0
  for _ in pairs(clients) do
    length = length + 1
  end
  if length > 0 then
    return true
  end

  local ft = vim.bo.filetype
  local configs = require "nvim_lsp/configs"
  for _, config in pairs(configs) do
    for _, config_ft in pairs(config["document_config"]["default_config"]["filetypes"]) do
      if config_ft == ft then
        return true
      end
    end
  end

  return false
end

return M
