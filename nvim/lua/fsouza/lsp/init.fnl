(import-macros {: if-nil} :helpers)

(local path (require :pl.path))

(local cache-dir (vim.fn.stdpath :cache))

(macro get-local-cmd [cmd]
  `(path.join config-dir :langservers :bin ,cmd))

(macro get-cache-path [...]
  `(path.join cache-dir :langservers ,...))

(macro get-cache-cmd [cmd]
  `(get-cache-path :bin ,cmd))

(macro config-log []
  `(let [level# (if vim.env.NVIM_DEBUG :trace :error)
         lsp-log# (require :vim.lsp.log)]
     (lsp-log#.set_level level#)
     (lsp-log#.set_format_func vim.inspect)))

(macro define-signs []
  (icollect [_ level (ipairs [:Error :Warn :Info :Hint])]
    (let [sign-name (.. :DiagnosticSign level)]
      `(vim.fn.sign_define ,sign-name
                           {:text "" :texthl ,sign-name :numhl ,sign-name}))))

(macro if-executable [name expr]
  `(when (= (vim.fn.executable ,name) 1)
     ,expr))

(do
  (define-signs)
  (config-log)
  (let [lsp (require :lspconfig)
        opts (require :fsouza.lsp.opts)]
    (if-executable :fnm
                   (let [tablex (require :fsouza.tablex)
                         nvim-python (path.join cache-dir :venv :bin :python3)
                         nvim-node-ls (get-local-cmd :node-lsp.py)]
                     (macro node-lsp [name ...]
                       `(let [mod# (. lsp ,name)
                              cmd# [nvim-python nvim-node-ls ,...]]
                          (mod#.setup (opts.with-defaults {:cmd cmd#}))))
                     (node-lsp :bashls :bash-language-server :start)
                     (node-lsp :cssls :vscode-css-language-server :--stdio)
                     (node-lsp :html :vscode-html-language-server :--stdio)
                     (node-lsp :tsserver :typescript-language-server :--stdio)
                     (node-lsp :yamlls :yaml-language-server :--stdio)
                     (let [schemastore (require :schemastore)]
                       (lsp.jsonls.setup (opts.with-defaults {:cmd [nvim-python
                                                                    nvim-node-ls
                                                                    :vscode-json-language-server
                                                                    :--stdio]
                                                              :settings {:format {:enable false}
                                                                         :json {:schemas (schemastore.json.schemas)}}})))
                     (lsp.pyright.setup (opts.with-defaults {:cmd [nvim-python
                                                                   nvim-node-ls
                                                                   :pyright-langserver
                                                                   :--stdio]
                                                             :settings {:pyright {}
                                                                        :python {:pythonPath :/usr/bin/python3
                                                                                 :analysis {:autoImportCompletions true
                                                                                            :autoSearchPaths true
                                                                                            :diagnosticMode :workspace
                                                                                            :typeCheckingMode (if-nil vim.g.pyright_type_checking_mode
                                                                                                                      :basic)
                                                                                            :useLibraryCodeForTypes true}}}
                                                             :on_init (fn [client]
                                                                        (let [pyright (require :fsouza.lsp.pyright)]
                                                                          (pyright.detect-pythonPath client))
                                                                        true)}))))
    (if-executable :go
                   (do
                     (lsp.gopls.setup (opts.with-defaults {:cmd [(get-cache-cmd :gopls)]
                                                           :root_dir (opts.root-pattern-with-fallback :go.mod)
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
                       (lsp.efm.setup (opts.with-defaults {:cmd [(get-cache-cmd :efm-langserver)]
                                                           :init_options {:documentFormatting true}
                                                           : settings
                                                           : filetypes
                                                           :on_init (fn [client]
                                                                      (efm.gen-config client)
                                                                      true)})))))
    (if-executable :dune
                   (lsp.ocamllsp.setup (opts.with-defaults {:root_dir (opts.root-pattern-with-fallback :.merlin
                                                                                                       :package.json)})))
    (if-executable :dotnet
                   (lsp.fsautocomplete.setup (opts.with-defaults {:root_dir (opts.root-pattern-with-fallback :*.fsproj
                                                                                                             :*.sln)})))
    (if-executable :sourcekit-lsp (lsp.sourcekit.setup (opts.with-defaults {})))
    (if-executable :clojure-lsp (lsp.clojure_lsp.setup (opts.with-defaults {})))))
