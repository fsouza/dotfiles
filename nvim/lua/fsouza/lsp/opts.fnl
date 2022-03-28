(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(local setup-symbols-outline
       (helpers.once #(let [symbols-outline (require :symbols-outline)]
                        (symbols-outline.setup {:highlight_hovered_item false
                                                :auto_preview false
                                                :keymaps {:toggle_preview [:<leader>i]
                                                          :close [:<leader>v]}
                                                :symbols {:File {:icon ">"
                                                                 :hl :TSURI}
                                                          :Module {:icon "Ｍ"
                                                                   :hl :TSNamespace}
                                                          :Namespace {:icon ">"
                                                                      :hl :TSNamespace}
                                                          :Package {:icon ">"
                                                                    :hl :TSNamespace}
                                                          :Class {:icon "𝓒"
                                                                  :hl :TSType}
                                                          :Method {:icon "ƒ"
                                                                   :hl :TSMethod}
                                                          :Property {:icon "ƒ"
                                                                     :hl :TSMethod}
                                                          :Field {:icon ">"
                                                                  :hl :TSField}
                                                          :Constructor {:icon "ƒ"
                                                                        :hl :TSConstructor}
                                                          :Enum {:icon "ℰ"
                                                                 :hl :TSType}
                                                          :Interface {:icon "ﰮ"
                                                                      :hl :TSType}
                                                          :Function {:icon "ƒ"
                                                                     :hl :TSFunction}
                                                          :Variable {:icon ">"
                                                                     :hl :TSConstant}
                                                          :Constant {:icon ">"
                                                                     :hl :TSConstant}
                                                          :String {:icon "𝓐"
                                                                   :hl :TSString}
                                                          :Number {:icon "#"
                                                                   :hl :TSNumber}
                                                          :Boolean {:icon "⊨"
                                                                    :hl :TSBoolean}
                                                          :Array {:icon "Ａ"
                                                                  :hl :TSConstant}
                                                          :Object {:icon "⦿"
                                                                   :hl :TSType}
                                                          :Key {:icon "🔐"
                                                                :hl :TSType}
                                                          :Null {:icon :NULL
                                                                 :hl :TSType}
                                                          :EnumMember {:icon ">"
                                                                       :hl :TSField}
                                                          :Struct {:icon "𝓢"
                                                                   :hl :TSType}
                                                          :Event {:icon ">"
                                                                  :hl :TSType}
                                                          :Operator {:icon "+"
                                                                     :hl :TSOperator}
                                                          :TypeParameter {:icon "𝙏"
                                                                          :hl :TSParameter}}})
                        symbols-outline)))

(fn attached [bufnr client]
  (let [detach (require :fsouza.lsp.detach)]
    (macro register-detach [cb]
      `(detach.register bufnr ,cb))
    (vim-schedule (let [mappings {:n [{:lhs :<leader>l
                                       :rhs #(vim.diagnostic.open_float {: bufnr
                                                                         :scope :line})}
                                      {:lhs :<leader>df
                                       :rhs #(mod-invoke :fsouza.lsp.diagnostics
                                                         :list-file-diagnostics)}
                                      {:lhs :<leader>dw
                                       :rhs #(mod-invoke :fsouza.lsp.diagnostics
                                                         :list-workspace-diagnostics)}
                                      {:lhs :<leader>dd
                                       :rhs #(mod-invoke :fsouza.plugin.fuzzy
                                                         :lsp_workspace_diagnostics)}
                                      {:lhs :<leader>cl
                                       :rhs #(mod-invoke :fsouza.lsp.buf-diagnostic
                                                         :buf-clear-all-diagnostics)}
                                      {:lhs :<c-n>
                                       :rhs #(vim.diagnostic.goto_next {:focusable false})}
                                      {:lhs :<c-p>
                                       :rhs #(vim.diagnostic.goto_prev {:focusable false})}]
                                  :i []
                                  :x []}]
                    (let [shell-post (require :fsouza.lsp.shell-post)]
                      (shell-post.on-attach {: bufnr : client})
                      (register-detach shell-post.on-detach))
                    (when (not= client.server_capabilities.completionProvider
                                nil)
                      (let [completion (require :fsouza.lsp.completion)]
                        (completion.on-attach client bufnr)
                        (register-detach (partial completion.on-detach client))))
                    (when (not= client.server_capabilities.renameProvider nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>r
                                     :rhs #(vim.lsp.buf.rename)}))
                    (when (not= client.server_capabilities.codeActionProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>cc
                                     :rhs #(mod-invoke :fsouza.lsp.code-action
                                                       :code-action)})
                      (table.insert mappings.x
                                    {:lhs :<leader>cc
                                     :rhs #(mod-invoke :fsouza.lsp.code-action
                                                       :visual-code-action)}))
                    (when (not= client.server_capabilities.declarationProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>gy
                                     :rhs #(vim.lsp.buf.declaration)})
                      (table.insert mappings.n
                                    {:lhs :<leader>py
                                     :rhs #(mod-invoke :fsouza.lsp.locations
                                                       :preview-declaration)}))
                    (when (not= client.server_capabilities.definitionProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>gd
                                     :rhs #(vim.lsp.buf.definition)})
                      (table.insert mappings.n
                                    {:lhs :<leader>pd
                                     :rhs #(mod-invoke :fsouza.lsp.locations
                                                       :preview-definition)}))
                    (when (not= client.server_capabilities.implementationProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>gi
                                     :rhs #(vim.lsp.buf.implementation)})
                      (table.insert mappings.n
                                    {:lhs :<leader>pi
                                     :rhs #(mod-invoke :fsouza.lsp.locations
                                                       :preview-implementation)}))
                    (when (not= client.server_capabilities.typeDefinitionProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>gt
                                     :rhs #(vim.lsp.type_definition)})
                      (table.insert mappings.n
                                    {:lhs :<leader>pt
                                     :rhs #(mod-invoke :fsouza.lsp.locations
                                                       :preview-type-definition)}))
                    (when (not= client.server_capabilities.documentFormattingProvider
                                nil)
                      (let [formatting (require :fsouza.lsp.formatting)]
                        (formatting.on-attach bufnr)
                        (register-detach formatting.on-detach)))
                    (when (not= client.server_capabilities.documentHighlightProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>s
                                     :rhs #(vim.lsp.buf.document_highlight)})
                      (table.insert mappings.n
                                    {:lhs :<leader>S
                                     :rhs #(vim.lsp.buf.clear_references)}))
                    (when (not= client.server_capabilities.documentSymbolProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>t
                                     :rhs #(mod-invoke :fsouza.plugin.fuzzy
                                                       :lsp_document_symbols)})
                      (table.insert mappings.n
                                    {:lhs :<leader>v
                                     :rhs #(let [symbols-outline (setup-symbols-outline)]
                                             (symbols-outline.toggle_outline))}))
                    (when (not= client.server_capabilities.referencesProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>q
                                     :rhs #(vim.lsp.buf.references)}))
                    (when (not= client.server_capabilities.hoverProvider nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>i :rhs #(vim.lsp.buf.hover)}))
                    (when (not= client.server_capabilities.signatureHelpProvider
                                nil)
                      (table.insert mappings.i
                                    {:lhs :<c-k>
                                     :rhs #(vim.lsp.buf.signature_help)}))
                    (when (not= client.server_capabilities.workspaceSymbolProvider
                                nil)
                      (table.insert mappings.n
                                    {:lhs :<leader>T
                                     :rhs #(let [{: lsp_workspace_symbols} (require :fsouza.plugin.fuzzy)
                                                 query (vim.fn.input "query：")]
                                             (when (not= query "")
                                               (lsp_workspace_symbols {: query})))}))
                    (when (not= client.server_capabilities.codeLensProvider nil)
                      (let [codelens (require :fsouza.lsp.codelens)]
                        (codelens.on-attach {: bufnr
                                             : client
                                             :mapping :<leader><cr>
                                             :can-resolve (not= (?. client.server_capabilities
                                                                    :codeLensProvider
                                                                    :resolveProvider)
                                                                nil)
                                             :supports-command (not= client.server_capabilities.executeCommandProvider
                                                                     nil)})
                        (register-detach codelens.on-detach)))
                    (vim-schedule (each [mode keymaps (pairs mappings)]
                                    (each [_ {: lhs : rhs} (ipairs keymaps)]
                                      (vim.keymap.set mode lhs rhs
                                                      {:silent true
                                                       :buffer bufnr})))
                                  (register-detach #(each [mode keymaps (pairs mappings)]
                                                      (each [_ {: lhs} (ipairs keymaps)]
                                                        (vim.keymap.del mode
                                                                        lhs
                                                                        {:buffer bufnr})))))))))

(fn on-attach [client bufnr]
  (let [bufnr (if-nil bufnr (vim.api.nvim_get_current_buf))
        bufnr (if (= bufnr 0) (vim.api.nvim_get_current_buf) bufnr)]
    (attached bufnr client)))

(fn with-defaults [opts]
  (let [capabilities (vim.lsp.protocol.make_client_capabilities)]
    (tset capabilities.workspace :executeCommand {:dynamicRegistration false})
    (let [defaults {:handlers (require :fsouza.lsp.handlers)
                    :on_attach on-attach
                    : capabilities
                    :root_dir #(vim.fn.getcwd)
                    :flags {:debounce_text_changes 0}}]
      (vim.tbl_extend :force defaults opts))))

(fn root-pattern-with-fallback [...]
  (let [lspconfig (require :lspconfig)
        find-root (lspconfig.util.root_pattern ...)]
    (fn [startpath]
      (if-nil (find-root startpath) (vim.fn.getcwd)))))

{: with-defaults : root-pattern-with-fallback}
