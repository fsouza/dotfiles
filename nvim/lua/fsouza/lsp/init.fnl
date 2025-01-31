(local disabled-methods
       {:efm {:textDocument/definition true}
        :ruff-server {:textDocument/hover true}})

(fn patch-server-capabilities [client]
  (let [capabilities-to-disable {:gopls [:semanticTokensProvider]}
        caps (or (. capabilities-to-disable client.name) [])]
    (each [_ cap (ipairs caps)]
      (tset client.server_capabilities cap nil))))

(fn patch-supports-method [client]
  (let [supports-method client.supports_method]
    (tset client :supports_method
          #(let [client $1
                 method $2
                 disabled (or (?. disabled-methods client.name method) false)]
             (and (not disabled) (supports-method client method))))))

;; for each method, have a function that returns [ACTION args]
;;
;; where [ACTION args] can be either:
;;
;;  - [ATTACH attach-fn]
;;  - [MAPPINGS [{: mode : lhs : rhs}]]
(local method-handlers
       (let [fuzzy (require :fsouza.lib.fuzzy)
             locations (require :fsouza.lsp.locations)]
         {:callHierarchy/incomingCalls #[:MAPPINGS
                                         [{:mode :n
                                           :lhs :<leader>lc
                                           :rhs fuzzy.lsp_incoming_calls}]]
          :callHierarchy/outgoingCalls #[:MAPPINGS
                                         [{:mode :n
                                           :lhs :<leader>lC
                                           :rhs fuzzy.lsp_outgoing_calls}]]
          :textDocument/codeAction #[:MAPPINGS
                                     [{:mode :n
                                       :lhs :<leader>cc
                                       :rhs vim.lsp.buf.code_action}
                                      {:mode :x
                                       :lhs :<leader>cc
                                       :rhs vim.lsp.buf.code_action}]]
          :textDocument/codeLens #[:ATTACH
                                   #(let [codelens (require :fsouza.lsp.codelens)]
                                      (codelens.on-attach {:bufnr $1
                                                           :mapping :<leader><cr>}))]
          :textDocument/completion #[:ATTACH
                                     (let [completion (require :fsouza.lsp.completion)]
                                       completion.on-attach)]
          :textDocument/declaration #[:MAPPINGS
                                      [{:mode :n
                                        :lhs :<leader>gy
                                        :rhs #(vim.lsp.buf.declaration {:on_list fuzzy.lsp-on-list})}
                                       {:mode :n
                                        :lhs :<leader>py
                                        :rhs locations.preview-declaration}]]
          :textDocument/definition #[:MAPPINGS
                                     [{:mode :n
                                       :lhs :<leader>gd
                                       :rhs #(vim.lsp.buf.definition {:on_list fuzzy.lsp-on-list})}
                                      {:mode :n
                                       :lhs :<leader>pd
                                       :rhs locations.preview-definition}]]
          :textDocument/documentHighlight #[:MAPPINGS
                                            [{:mode :n
                                              :lhs :<leader>s
                                              :rhs #(do
                                                      (vim.lsp.util.buf_clear_references)
                                                      (vim.lsp.buf.document_highlight))}
                                             {:mode :n
                                              :lhs :<leader>S
                                              :rhs vim.lsp.buf.clear_references}]]
          :textDocument/documentSymbol #[:MAPPINGS
                                         [{:mode :n
                                           :lhs :<leader>t
                                           :rhs fuzzy.lsp_document_symbols}]]
          :textDocument/formatting #(let [bufnr $2]
                                      [:MAPPINGS
                                       [{:mode :n
                                         :lhs :<leader>f
                                         :rhs #(let [formatting (require :fsouza.lsp.formatting)]
                                                 (formatting.fmt bufnr))}]])
          :textDocument/hover #[:MAPPINGS
                                [{:mode :n
                                  :lhs :<leader>i
                                  :rhs vim.lsp.buf.hover}]]
          :textDocument/implementation #[:MAPPINGS
                                         [{:mode :n
                                           :lhs :<leader>gi
                                           :rhs #(vim.lsp.buf.implementation {:on_list fuzzy.lsp-on-list})}
                                          {:mode :n
                                           :lhs :<leader>pi
                                           :rhs locations.preview-implementation}]]
          :textDocument/references #[:MAPPINGS
                                     [{:mode :n
                                       :lhs :<leader>q
                                       :rhs #(vim.lsp.buf.references nil
                                                                     ;; TODO: reference filtering breaks renaming. I should fix it.
                                                                     {:on_list #(let [references (require :fsouza.lsp.references)]
                                                                                  (references.on-list $...))})}]]
          :textDocument/rename #(let [client $1
                                      bufnr $2]
                                  [:MAPPINGS
                                   [{:mode :n
                                     :lhs :<leader>r
                                     :rhs #(let [rename (require :fsouza.lsp.rename)]
                                             (rename.rename client bufnr))}]])
          :textDocument/signatureHelp #[:MAPPINGS
                                        [{:mode :i
                                          :lhs :<c-k>
                                          :rhs vim.lsp.buf.signature_help}]]
          :textDocument/typeDefinition #[:MAPPINGS
                                         [{:mode :n
                                           :lhs :<leader>gt
                                           :rhs #(vim.lsp.buf.type_definition {:on_list fuzzy.lsp-on-list})}
                                          {:mode :n
                                           :lhs :<leader>pt
                                           :rhs locations.preview-type-definition}]]
          :workspace/symbol #[:MAPPINGS
                              [{:mode :n
                                :lhs :<leader>T
                                :rhs #(let [query (vim.fn.input "query：")]
                                        (when (not= query "")
                                          (fuzzy.lsp_workspace_symbols {:lsp_query query})))}]]}))

(fn register-method [name client bufnr]
  (fn handle-attach [attach-fn]
    (attach-fn bufnr))

  (fn handle-mappings [mappings]
    (each [_ {: mode : lhs : rhs} (ipairs mappings)]
      (vim.keymap.set mode lhs rhs {:silent true :buffer bufnr})))

  (let [handler (. method-handlers name)]
    (when (and handler (client:supports_method name {: bufnr}))
      (let [result (handler client bufnr)]
        (match result
          [:ATTACH attach-fn] (handle-attach attach-fn)
          [:MAPPINGS mappings] (handle-mappings mappings))))))

(fn diag-open-float [scope]
  (vim.schedule #(let [(_ winid) (vim.diagnostic.open_float {:source :if_many
                                                             : scope
                                                             :focusable false
                                                             :border :solid})]
                   (when winid
                     (let [p (require :fsouza.lib.popup)]
                       (p.stylize winid))))))

(fn diag-jump [jump-fn]
  (jump-fn {:float false})
  (diag-open-float :cursor))

(fn lsp-attach [{:buf bufnr :data {:client_id client-id}}]
  (let [client (vim.lsp.get_client_by_id client-id)
        shell-post (require :fsouza.lsp.shell-post)
        diagnostics (require :fsouza.lsp.diagnostics)
        fuzzy (require :fsouza.lib.fuzzy)
        mappings [{:lhs :<leader>ll :rhs #(diag-open-float :line)}
                  {:lhs :<leader>df :rhs diagnostics.list-file-diagnostics}
                  {:lhs :<leader>dw
                   :rhs diagnostics.list-workspace-diagnostics}
                  {:lhs :<leader>dd :rhs fuzzy.lsp_workspace_diagnostics}
                  {:lhs :<c-n> :rhs #(diag-jump vim.diagnostic.goto_next)}
                  {:lhs :<c-p> :rhs #(diag-jump vim.diagnostic.goto_prev)}]]
    (patch-server-capabilities client)
    (patch-supports-method client)
    (shell-post.on-attach bufnr)
    (each [method _ (pairs method-handlers)]
      (register-method method client bufnr))
    (diagnostics.on-attach)
    (tset (. vim.bo bufnr) :formatexpr nil)
    (each [_ {: lhs : rhs} (ipairs mappings)]
      (vim.keymap.set :n lhs rhs {:silent true :buffer bufnr}))))

(macro config-log []
  `(let [level# (if vim.env.NVIM_DEBUG :trace :error)
         lsp-log# (require :vim.lsp.log)]
     (lsp-log#.set_level level#)
     (lsp-log#.set_format_func vim.inspect)))

(fn config-diagnostics []
  (let [empty-s (setmetatable {} {:__index #""})]
    (vim.diagnostic.config {:underline true
                            :virtual_text false
                            :update_in_insert false
                            :signs {:text empty-s
                                    :numhl {vim.diagnostic.severity.ERROR :DiagnosticSignError
                                            vim.diagnostic.severity.WARN :DiagnosticSignWarn
                                            vim.diagnostic.severity.INFO :DiagnosticSignInfo
                                            vim.diagnostic.severity.HINT :DiagnosticSignHint}}})))

(fn set-defaults [client bufnr]
  (when (client:supports_method :textDocument/diagnostic)
    (vim.lsp.diagnostic._enable bufnr)))

(fn setup []
  (config-diagnostics)
  (config-log)
  (tset vim.lsp :_set_defaults set-defaults)
  (let [{: augroup} (require :fsouza.lib.nvim-helpers)]
    (augroup :fsouza__LspAttach [{:events [:LspAttach] :callback lsp-attach}])))

{: setup : register-method}
