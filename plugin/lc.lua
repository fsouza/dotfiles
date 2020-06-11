local lsp = require 'nvim_lsp'

lsp.bashls.setup {
  cmd = { "vim-nodels", "bash-language-server", "start" };
};

lsp.cssls.setup {
  cmd = { "vim-nodels", "css-laguageserver", "--stdio" };
};

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
};

lsp.jsonls.setup {
  cmd = { "vim-nodels", "vscode-json-languageserver", "--stdio" };
};

lsp.ocamllsp.setup {
  cmd = { "vim-ocaml-lsp" };
};

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
};

lsp.rust_analyzer.setup{};

lsp.tsserver.setup {
  cmd = { "vim-nodels", "typescript-language-server", "--stdio" };
};

lsp.vimls.setup {
  cmd = { "vim-nodels",  "vim-language-server", "--stdio" };
};

lsp.yamlls.setup {
  cmd = { "vim-nodels", "yaml-language-server", "--stdio" };
};
