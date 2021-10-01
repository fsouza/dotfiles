(local helpers (require "fsouza.lib.nvim_helpers"))

(local setup-symbols-outline
  (helpers.once (fn []
                  (let [symbols-outline (require "symbols-outline")]
                    (symbols-outline.setup {:highlight_hovered_item false
                                            :auto_preview false
                                            :keymaps {:toggle_preview ["<leader>i"]
                                                      :close ["<leader>v"]}
                                            :symbols {:File {:icon ">"
                                                             :hl "TSURI"}
                                                      :Module {:icon "Ｍ"
                                                               :hl "TSNamespace"}
                                                      :Namespace {:icon ">"
                                                                  :hl "TSNamespace"}
                                                      :Package {:icon ">"
                                                                :hl "TSNamespace"}
                                                      :Class {:icon "𝓒"
                                                              :hl "TSType"}
                                                      :Method {:icon "ƒ"
                                                               :hl "TSMethod"}
                                                      :Property {:icon "ƒ"
                                                                 :hl "TSMethod"}
                                                      :Field {:icon ">"
                                                              :hl "TSField"}
                                                      :Constructor {:icon "ƒ"
                                                                    :hl "TSConstructor"}
                                                      :Enum {:icon "ℰ"
                                                             :hl "TSType"}
                                                      :Interface {:icon "ﰮ"
                                                                  :hl "TSType"}
                                                      :Function {:icon "ƒ"
                                                                 :hl "TSFunction"}
                                                      :Variable {:icon ">"
                                                                 :hl "TSConstant"}
                                                      :Constant {:icon ">"
                                                                 :hl "TSConstant"}
                                                      :String {:icon "𝓐"
                                                               :hl "TSString"}
                                                      :Number {:icon "#"
                                                               :hl "TSNumber"}
                                                      :Boolean {:icon "⊨"
                                                                :hl "TSBoolean"}
                                                      :Array {:icon "Ａ"
                                                              :hl "TSConstant"}
                                                      :Object {:icon "⦿"
                                                               :hl "TSType"}
                                                      :Key {:icon "🔐"
                                                            :hl "TSType"}
                                                      :Null {:icon "NULL"
                                                             :hl "TSType"}
                                                      :EnumMember {:icon ">"
                                                                   :hl "TSField"}
                                                      :Struct {:icon "𝓢"
                                                               :hl "TSType"}
                                                      :Event {:icon ">"
                                                              :hl "TSType"}
                                                      :Operator {:icon "+"
                                                                 :hl "TSOperator"}
                                                      :TypeParameter {:icon "𝙏"
                                                                      :hl "TSParameter"}}})
                    symbols-outline))))

(local buf-diag-mod (require "fsouza.lsp.buf_diagnostic"))

(local diag-mod (require "fsouza.lsp.diagnostics"))

(local fuzzy-mod (require "fsouza.plugin.fuzzy"))

(local code-action (require "fsouza.lsp.code_action"))

(local locations-mod (require "fsouza.lsp.locations"))

(local cmds {:show-line-diagnostics (helpers.fn-map (partial vim.diagnostic.show_line_diagnostics {:focusable false}))
             :list-file-diagnostics (helpers.fn-map diag-mod.list-file-diagnostics)
             :list-workspace-diagnostics (helpers.fn-map diag-mod.list-workspace-diagnostics)
             :fuzzy-workspace-diagnostics (helpers.fn-map fuzzy-mod.lsp_workspace_diagnostics)
             :clear-buffer-diagnostics (helpers.fn-map buf-diag-mod.buf-clear-all-diagnostics)
             :goto-next-diagnostic (helpers.fn-map (partial vim.diagnostic.goto_next {:popup_opts {:focusable false}}))
             :goto-prev-diagnostic (helpers.fn-map (partial vim.diagnostic.goto_prev {:popup_opts {:focusable false}}))
             :rename (helpers.fn-map vim.lsp.buf.rename)
             :code-action (helpers.fn-map code-action.code-action)
             :visual-code-action (helpers.fn-map code-action.visual-code-action)
             :highlight-references (helpers.fn-map vim.lsp.buf.document_highlight)
             :clear-references (helpers.fn-map vim.lsp.buf.clear_references)
             :list-document-symbols (helpers.fn-map fuzzy-mod.lsp_document_symbols)
             :find-references (helpers.fn-map vim.lsp.buf.references)
             :goto-declaration (helpers.fn-map vim.lsp.buf.declaration)
             :preview-declaration (helpers.fn-map locations-mod.preview-declaration)
             :goto-definition (helpers.fn-map vim.lsp.buf.definition)
             :preview-definition (helpers.fn-map locations-mod.preview-definition)
             :goto-implementation (helpers.fn-map vim.lsp.buf.implementation)
             :preview-implementation (helpers.fn-map locations-mod.preview-implementation)
             :goto-type-definition (helpers.fn-map vim.lsp.buf.type_definition)
             :preview-type-definition (helpers.fn-map locations-mod.preview-type-definition)
             :display-information (helpers.fn-map vim.lsp.buf.hover)
             :display-signature-help (helpers.fn-map vim.lsp.buf.signature_help)
             :query-workspace-symbols (helpers.fn-map (fn []
                                                        (let [query (vim.fn.input "query：")]
                                                          (when (not= query "")
                                                            (fuzzy-mod.lsp_workspace_symbols {:query query})))))
             :symbols-outline (helpers.fn-map (fn []
                                                (let [symbols-outline (setup-symbols-outline)]
                                                  (symbols-outline.toggle_outline))))})

(macro schedule [expr]
  `(vim.schedule (fn []
                   ,expr)))

(fn attached [bufnr client]
  (let [detach (require "fsouza.lsp.detach")]
    (macro register-detach [cb]
      `(detach.register bufnr ,cb))

    (schedule
      (let [mappings {:n [{:lhs "<leader>l" :rhs cmds.show-line-diagnostics :opts {:silent true}}
                          {:lhs "<leader>df" :rhs cmds.list-file-diagnostics :opts {:silent true}}
                          {:lhs "<leader>dw" :rhs cmds.list-workspace-diagnostics :opts {:silent true}}
                          {:lhs "<leader>dd" :rhs cmds.fuzzy-workspace-diagnostics :opts {:silent true}}
                          {:lhs "<leader>cl" :rhs cmds.clear-buffer-diagnostics :opts {:silent true}}
                          {:lhs "<c-n>" :rhs cmds.goto-next-diagnostic :opts {:silent true}}
                          {:lhs "<c-p>" :rhs cmds.goto-prev-diagnostic :opts {:silent true}}]
                      :i []
                      :x []}]

        (when client.resolved_capabilities.text_document_did_change
          (let [shell-post (require "fsouza.lsp.shell_post")]
            (shell-post.on-attach {:bufnr bufnr
                                   :client client})
            (register-detach shell-post.on-detach)))

        (when client.resolved_capabilities.completion
          (let [completion (require "fsouza.lsp.completion")]
            (completion.on-attach bufnr)
            (register-detach completion.on-detach)))

        (when client.resolved_capabilities.rename
          (table.insert mappings.n {:lhs "<leader>r"
                                    :rhs cmds.rename
                                    :opts {:silent true}}))

        (when client.resolved_capabilities.code_action
          (table.insert mappings.n {:lhs "<leader>cc"
                                    :rhs cmds.code-action
                                    :opts {:silent true}})
          (table.insert mappings.x {:lhs "<leader>cc"
                                    :rhs cmds.visual-code-action
                                    :opts {:silent true}}))

        (when client.resolved_capabilities.declaration
          (table.insert mappings.n {:lhs "<leader>gy" :rhs cmds.goto-declaration :opts {:silent true}})
          (table.insert mappings.n {:lhs "<leader>py" :rhs cmds.preview-declaration :opts {:silent true}}))

        (when client.resolved_capabilities.goto_definition
          (table.insert mappings.n {:lhs "<leader>gd" :rhs cmds.goto-definition :opts {:silent true}})
          (table.insert mappings.n {:lhs "<leader>pd" :rhs cmds.preview-definition :opts {:silent true}}))

        (when client.resolved_capabilities.implementation
          (table.insert mappings.n {:lhs "<leader>gi" :rhs cmds.goto-implementation :opts {:silent true}})
          (table.insert mappings.n {:lhs "<leader>pi" :rhs cmds.preview-implementation :opts {:silent true}}))

        (when client.resolved_capabilities.type_defintion
          (table.insert mappings.n {:lhs "<leader>gt" :rhs cmds.goto-type-definition :opts {:silent true}})
          (table.insert mappings.n {:lhs "<leader>pt" :rhs cmds.preview-type-definition :opts {:silent true}}))

        (when client.resolved_capabilities.document_formatting
          (let [formatting (require "fsouza.lsp.formatting")]
            (formatting.on-attach client bufnr)
            (register-detach formatting.on-detach)))

        (when client.resolved_capabilities.document_highlight
          (table.insert mappings.n {:lhs "<leader>s"
                                   :rhs cmds.highlight-references
                                   :opts {:silent true}})
          (table.insert mappings.n {:lhs "<leader>S"
                                   :rhs cmds.clear-references
                                   :opts {:silent true}}))

        (when client.resolved_capabilities.document_symbol
          (table.insert mappings.n {:lhs "<leader>t"
                                   :rhs cmds.list-document-symbols
                                   :opts {:silent true}})
          (table.insert mappings.n {:lhs "<leader>v"
                                   :rhs cmds.symbols-outline
                                   :opts {:silent true}}))

        (when client.resolved_capabilities.find_references
          (table.insert mappings.n {:lhs "<leader>q"
                                   :rhs cmds.find-references
                                   :opts {:silent true}}))

        (when client.resolved_capabilities.hover
          (table.insert mappings.n {:lhs "<leader>i"
                                   :rhs cmds.display-information
                                   :opts {:silent true}}))


        (when client.resolved_capabilities.signature_help
          (table.insert mappings.i {:lhs "<c-k>"
                                   :rhs cmds.display-signature-help
                                   :opts {:silent true}}))

        (when client.resolved_capabilities.workspace_symbol
          (table.insert mappings.n {:lhs "<leader>T"
                                   :rhs cmds.query-workspace-symbols
                                   :opts {:silent true}}))

        (when client.resolved_capabilities.code_lens
          (let [codelens (require "fsouza.lsp.code_lens")]
            (codelens.on-attach {:bufnr bufnr
                                 :client client
                                 :mapping "<leader><cr>"
                                 :can-resolve client.resolved_capabilities.code_lens_resolve
                                 :supports-command client.resolved_capabilities.execute_command})
            (register-detach codelens.on-detach)))

        (let [progress (require "fsouza.lsp.progress")]
          (progress.on-attach))

        (schedule
          (do
            (helpers.create-mappings mappings bufnr)
            (register-detach (partial helpers.remove-mappings mappings bufnr))))))))

(fn on-attach [client bufnr]
  (let [bufnr (helpers.if-nil bufnr vim.api.nvim_get_current_buf)
        bufnr (if (= bufnr 0) (vim.api.nvim_get_current_buf) bufnr)]
    (attached bufnr client)))

(fn with-defaults [opts]
  (let [capabilities (vim.lsp.protocol.make_client_capabilities)
        cmp-nvim-lsp (require "cmp_nvim_lsp")]
    (tset capabilities.workspace :executeCommand {:dynamicRegistration false})

    (let [defaults {:handlers (require "fsouza.lsp.handlers")
                    :on_attach on-attach
                    :capabilities (cmp-nvim-lsp.update_capabilities capabilities {:snippetSupport false
                                                                                  :preselectSupport false
                                                                                  :commitCharactersSupport false})
                    :root_dir (partial vim.fn.getcwd)}]
      (vim.tbl_extend "force" defaults opts))))

(fn root-pattern-with-fallback [...]
  (let [lspconfig (require "lspconfig")
        find-root (lspconfig.util.root_pattern ...)]
    (fn [startpath]
      (helpers.if-nil (find-root startpath) (partial vim.fn.getcwd)))))

{:with-defaults with-defaults
 :root-pattern-with-fallback root-pattern-with-fallback}
