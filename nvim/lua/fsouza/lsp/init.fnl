(import-macros {: if-nil} :helpers)

(local path (require :pl.path))

(local cache-dir (vim.fn.stdpath "cache"))

(fn get-local-cmd [cmd]
  (path.join config-dir "langservers" "bin" cmd))

(fn get-cache-cmd [cmd]
  (path.join cache-dir "langservers" "bin" cmd))

(fn set-log-level []
  (let [level (if vim.env.NVIM_DEBUG
                "TRACE"
                "ERROR")
        lsp-log (require :vim.lsp.log)]
    (lsp-log.set_level level)))

(fn patch-lsp []
  (let [fns-to-patch [:show_line_diagnostics
                      :show_position_diagnostics]]
    (each [_ fn-to-patch (ipairs fns-to-patch)]
      (let [original-fn (. vim.diagnostic fn-to-patch)]
        (tset vim.diagnostic fn-to-patch (fn [...]
                                           (let [(bufnr winid) (original-fn ...)
                                                 color (require :fsouza.color)]
                                             (color.set-popup-winid winid)
                                             (values bufnr winid))))))))

(fn define-signs []
  (each [_ level (ipairs ["Error" "Warn" "Info" "Hint"])]
    (let [sign-name (.. "DiagnosticSign" level)]
      (vim.fn.sign_define sign-name {:text ""
                                     :texthl sign-name
                                     :numhl sign-name}))))

(macro if-executable [name expr]
  `(when (= (vim.fn.executable ,name) 1)
     ,expr))

(do
  (patch-lsp)
  (define-signs)

  (set-log-level)
  (let [lsp (require :lspconfig)
        opts (require :fsouza.lsp.opts)]

    (if-executable "fnm"
      (let [tablex (require :fsouza.tablex)
            nvim-python (path.join cache-dir "venv" "bin" "python3")
            nvim-node-ls (get-local-cmd "node-lsp.py")]

        (macro node-lsp [name ...]
          `(let [mod# (. lsp ,name)
                 cmd# [nvim-python nvim-node-ls ,...]]

             (mod#.setup (opts.with-defaults {:cmd cmd#}))))


        (node-lsp :bashls "bash-language-server" "start")
        (node-lsp :cssls "vscode-css-language-server" "--stdio")
        (node-lsp :html "vscode-html-language-server" "--stdio")
        (node-lsp :jsonls "vscode-json-language-server" "--stdio")
        (node-lsp :tsserver "typescript-language-server" "--stdio")
        (node-lsp :yamlls "yaml-language-server" "--stdio")

        (lsp.pyright.setup (opts.with-defaults {:cmd [nvim-python
                                                      nvim-node-ls
                                                      "pyright-langserver"
                                                      "--stdio"]
                                                :settings {:pyright {}
                                                           :python {:pythonPath "/usr/bin/python3"
                                                                    :analysis {:autoImportCompletions true
                                                                               :autoSearchPaths true
                                                                               :diagnosticMode "workspace"
                                                                               :typeCheckingMode (if-nil vim.g.pyright_type_checking_mode "basic")
                                                                               :useLibraryCodeForTypes true}}}
                                                :on_init (fn [client]
                                                           (let [pyright (require :fsouza.lsp.pyright)]
                                                             (pyright.detect-pythonPath client))
                                                           true)}))))

    (if-executable "go"
      (do
        (lsp.gopls.setup (opts.with-defaults {:cmd [(get-cache-cmd "gopls")]
                                              :root_dir (opts.root-pattern-with-fallback "go.mod")
                                              :init_options {:deepCompletion false
                                                             :staticcheck true
                                                             :analyses {:fillreturns true
                                                                        :nonewvars true
                                                                        :undeclaredname true
                                                                        :unusedparams true
                                                                        :ST1000 false}
                                                             :linksInHover false
                                                             :codelenses {:vendor false}
                                                             :gofumpt true}}))

        (let [efm (require :fsouza.lsp.efm)
              (settings filetypes) (efm.basic-settings)]
          (lsp.efm.setup (opts.with-defaults {:cmd [(get-cache-cmd "efm-langserver")]
                                              :init_options {:documentFormatting true}
                                              :settings settings
                                              :filetypes filetypes
                                              :on_init (fn [client]
                                                         (efm.gen-config client)
                                                         true)})))))

    (if-executable "dune"
      (lsp.ocamllsp.setup (opts.with-defaults {:cmd [(path.join cache-dir "langservers" "ocaml-lsp" "_build"
                                                                "install" "default" "bin" "ocamllsp")]
                                               :root_dir (opts.root-pattern-with-fallback ".merlin" "package.json")})))

    (if-executable "dotnet"
      (lsp.fsautocomplete.setup (opts.with-defaults {:root_dir (opts.root-pattern-with-fallback "*.fsproj" "*.sln")})))

    (if-executable "sourcekit-lsp"
      (lsp.sourcekit.setup (opts.with-defaults {})))))
