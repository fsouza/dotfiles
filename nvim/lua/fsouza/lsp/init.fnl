(import-macros {: mod-invoke} :helpers)

(fn mutate-server-capabilities [client]
  (let [per-server-caps {:jdtls [:codeLensProvider]
                         :ocaml-lsp [:semanticTokensProvider]
                         :sorbet [:definitionProvider
                                  :referencesProvider
                                  :hoverProvider
                                  :typeDefinitionProvider]}
        caps (or (. per-server-caps client.name) [])]
    (each [_ cap (ipairs caps)]
      (tset client.server_capabilities cap nil))))

(fn lsp-attach [{:buf bufnr :data {:client_id client-id}}]
  (let [client (vim.lsp.get_client_by_id client-id)
        detach (require :fsouza.lsp.detach)
        shell-post (require :fsouza.lsp.shell-post)
        mappings {:n [{:lhs :<leader>l
                       :rhs #(vim.diagnostic.open_float {: bufnr
                                                         :scope :line
                                                         :source :if_many})}
                      {:lhs :<leader>df
                       :rhs #(mod-invoke :fsouza.lsp.diagnostics
                                         :list-file-diagnostics)}
                      {:lhs :<leader>dw
                       :rhs #(mod-invoke :fsouza.lsp.diagnostics
                                         :list-workspace-diagnostics)}
                      {:lhs :<leader>dd
                       :rhs #(mod-invoke :fsouza.lib.fuzzy
                                         :lsp_workspace_diagnostics)}
                      {:lhs :<leader>cl
                       :rhs #(mod-invoke :fsouza.lsp.buf-diagnostic
                                         :buf-clear-all-diagnostics)}
                      {:lhs :<c-n>
                       :rhs #(vim.diagnostic.goto_next {:focusable false
                                                        :float {:source :if_many}})}
                      {:lhs :<c-p>
                       :rhs #(vim.diagnostic.goto_prev {:focusable false
                                                        :float {:source :if_many}})}]
                  :i []
                  :x []}]
    (mutate-server-capabilities client)
    (shell-post.on-attach bufnr)
    (detach.register bufnr shell-post.on-detach)
    (when (not= client.server_capabilities.completionProvider nil)
      (let [completion (require :fsouza.lsp.completion)]
        (completion.on-attach bufnr)
        (detach.register bufnr completion.on-detach)))
    (when (not= client.server_capabilities.renameProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>r
                     :rhs #(mod-invoke :fsouza.lsp.rename :rename)}))
    (when (not= client.server_capabilities.codeActionProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>cc
                     :rhs #(mod-invoke :fsouza.lsp.code-action :code-action)})
      (table.insert mappings.x
                    {:lhs :<leader>cc
                     :rhs #(mod-invoke :fsouza.lsp.code-action
                                       :visual-code-action)}))
    (when (not= client.server_capabilities.declarationProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>gy :rhs #(vim.lsp.buf.declaration)})
      (table.insert mappings.n
                    {:lhs :<leader>py
                     :rhs #(mod-invoke :fsouza.lsp.locations
                                       :preview-declaration)}))
    (when (not= client.server_capabilities.definitionProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>gd :rhs #(vim.lsp.buf.definition)})
      (table.insert mappings.n
                    {:lhs :<leader>pd
                     :rhs #(mod-invoke :fsouza.lsp.locations
                                       :preview-definition)}))
    (when (not= client.server_capabilities.implementationProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>gi :rhs #(vim.lsp.buf.implementation)})
      (table.insert mappings.n
                    {:lhs :<leader>pi
                     :rhs #(mod-invoke :fsouza.lsp.locations
                                       :preview-implementation)}))
    (when (not= client.server_capabilities.typeDefinitionProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>gt :rhs #(vim.lsp.buf.type_definition)})
      (table.insert mappings.n
                    {:lhs :<leader>pt
                     :rhs #(mod-invoke :fsouza.lsp.locations
                                       :preview-type-definition)}))
    (when (not= client.server_capabilities.documentFormattingProvider nil)
      (mod-invoke :fsouza.lsp.auto-action :setup)
      (let [formatting (require :fsouza.lsp.formatting)]
        (formatting.on-attach bufnr)
        (detach.register bufnr formatting.on-detach)))
    (when (not= client.server_capabilities.documentHighlightProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>s :rhs #(vim.lsp.buf.document_highlight)})
      (table.insert mappings.n
                    {:lhs :<leader>S :rhs #(vim.lsp.buf.clear_references)}))
    (when (not= client.server_capabilities.documentSymbolProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>t
                     :rhs #(mod-invoke :fsouza.lib.fuzzy :lsp_document_symbols)}))
    (when (not= client.server_capabilities.referencesProvider nil)
      (table.insert mappings.n {:lhs :<leader>q :rhs #(vim.lsp.buf.references)}))
    (when (not= client.server_capabilities.hoverProvider nil)
      (table.insert mappings.n {:lhs :<leader>i :rhs #(vim.lsp.buf.hover)}))
    (when (not= client.server_capabilities.signatureHelpProvider nil)
      (table.insert mappings.i {:lhs :<c-k> :rhs #(vim.lsp.buf.signature_help)}))
    (when (not= client.server_capabilities.workspaceSymbolProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>T
                     :rhs #(let [query (vim.fn.input "query：")]
                             (when (not= query "")
                               (mod-invoke :fsouza.lib.fuzzy
                                           :lsp_workspace_symbols
                                           {:lsp_query query})))}))
    (when (not= client.server_capabilities.codeLensProvider nil)
      (let [codelens (require :fsouza.lsp.codelens)]
        (codelens.on-attach {: bufnr :mapping :<leader><cr>})
        (detach.register bufnr codelens.on-detach)))
    (when (not= client.server_capabilities.callHierarchyProvider nil)
      (table.insert mappings.n
                    {:lhs :<leader>lc
                     :rhs #(mod-invoke :fsouza.lib.fuzzy :lsp_incoming_calls)})
      (table.insert mappings.n
                    {:lhs :<leader>lC
                     :rhs #(mod-invoke :fsouza.lib.fuzzy :lsp_outgoing_calls)}))
    (mod-invoke :fsouza.lsp.diagnostics :on-attach)
    (each [mode keymaps (pairs mappings)]
      (each [_ {: lhs : rhs} (ipairs keymaps)]
        (vim.keymap.set mode lhs rhs {:silent true :buffer bufnr}))
      (detach.register bufnr
                       #(each [mode keymaps (pairs mappings)]
                          (each [_ {: lhs} (ipairs keymaps)]
                            (vim.keymap.del mode lhs {:buffer bufnr})))))))

(macro config-log []
  `(let [level# (if vim.env.NVIM_DEBUG :trace :off)
         lsp-log# (require :vim.lsp.log)]
     (lsp-log#.set_level level#)
     (lsp-log#.set_format_func vim.inspect)))

(macro define-signs []
  (icollect [_ level (ipairs [:Error :Warn :Info :Hint])]
    (let [sign-name (.. :DiagnosticSign level)]
      `(vim.fn.sign_define ,sign-name {:text "" :numhl ,sign-name}))))

(fn setup []
  (define-signs)
  (config-log)
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__LspAttach
              [{:events [:LspAttach] :callback lsp-attach}])
  (mod-invoke :fsouza.lsp.buf-diagnostic :register-filter :pyright
              #(mod-invoke :fsouza.lsp.servers.pyright :valid-diagnostic $1))
  (mod-invoke :fsouza.lsp.buf-diagnostic :register-filter :rust_analyzer
              #(mod-invoke :fsouza.lsp.servers.rust-analyzer :valid-diagnostic
                           $1)))

{: setup}
