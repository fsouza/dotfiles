(import-macros {: mod-invoke} :helpers)

(local disabled-methods {:efm {:textDocument/definition true}})

(fn patch-supports-method [client]
  (let [supports-method client.supports_method]
    (tset client :supports_method
          #(let [method $1
                 disabled (or (?. disabled-methods client.name method) false)]
             (and (not disabled) (supports-method method))))))

;; for each method, have a function that returns [ACTION args]
;;
;; where [ACTION args] can be either:
;;
;;  - [ATTACH attach-fn]
;;  - [MAPPINGS [{: mode : lhs : rhs}]]
(local method-handlers
       {:callHierarchy/incomingCalls #[:MAPPINGS
                                       [{:mode :n
                                         :lhs :<leader>lc
                                         :rhs #(mod-invoke :fsouza.lib.fuzzy
                                                           :lsp_incoming_calls)}]]
        :callHierarchy/outgoingCalls #[:MAPPINGS
                                       [{:mode :n
                                         :lhs :<leader>lC
                                         :rhs #(mod-invoke :fsouza.lib.fuzzy
                                                           :lsp_outgoing_calls)}]]
        :textDocument/codeAction #[:MAPPINGS
                                   [{:mode :n
                                     :lhs :<leader>cc
                                     :rhs #(mod-invoke :fsouza.lsp.code-action
                                                       :code-action)}
                                    {:mode :x
                                     :lhs :<leader>cc
                                     :rhs #(mod-invoke :fsouza.lsp.code-action
                                                       :visual-code-action)}]]
        :textDocument/codeLens #[:ATTACH
                                 #(mod-invoke :fsouza.lsp.codelens :on-attach
                                              {:bufnr $1
                                               :mapping :<leader><cr>})]
        :textDocument/completion #[:ATTACH
                                   #(mod-invoke :fsouza.lsp.completion
                                                :on-attach $1)]
        :textDocument/declaration #[:MAPPINGS
                                    [{:mode :n
                                      :lhs :<leader>gy
                                      :rhs vim.lsp.buf.declaration}
                                     {:mode :n
                                      :lhs :<leader>py
                                      :rhs #(mod-invoke :fsouza.lsp.locations
                                                        :preview-declaration)}]]
        :textDocument/definition #[:MAPPINGS
                                   [{:mode :n
                                     :lhs :<leader>gd
                                     :rhs vim.lsp.buf.definition}
                                    {:mode :n
                                     :lhs :<leader>pd
                                     :rhs #(mod-invoke :fsouza.lsp.locations
                                                       :preview-definition)}]]
        :textDocument/documentHighlight #[:MAPPINGS
                                          [{:mode :n
                                            :lhs :<leader>s
                                            :rhs vim.lsp.buf.document_highlight}
                                           {:mode :n
                                            :lhs :<leader>S
                                            :rhs vim.lsp.buf.clear_references}]]
        :textDocument/documentSymbol #[:MAPPINGS
                                       [{:mode :n
                                         :lhs :<leader>t
                                         :rhs #(mod-invoke :fsouza.lib.fuzzy
                                                           :lsp_document_symbols)}]]
        :textDocument/formatting #(let [bufnr $2]
                                    [:MAPPINGS
                                     [{:mode :n
                                       :lhs :<leader>f
                                       :rhs #(mod-invoke :fsouza.lsp.formatting
                                                         :fmt bufnr)}]])
        :textDocument/hover #[:MAPPINGS
                              [{:mode :n
                                :lhs :<leader>i
                                :rhs vim.lsp.buf.hover}]]
        :textDocument/implementation #[:MAPPINGS
                                       [{:mode :n
                                         :lhs :<leader>gi
                                         :rhs vim.lsp.buf.implementation}
                                        {:mode :n
                                         :lhs :<leader>pi
                                         :rhs #(mod-invoke :fsouza.lsp.locations
                                                           :preview-implementation)}]]
        :textDocument/references #[:MAPPINGS
                                   [{:mode :n
                                     :lhs :<leader>q
                                     :rhs vim.lsp.buf.references}]]
        :textDocument/rename #(let [client $1
                                    bufnr $2]
                                [:MAPPINGS
                                 [{:mode :n
                                   :lhs :<leader>r
                                   :rhs #(mod-invoke :fsouza.lsp.rename :rename
                                                     client bufnr)}]])
        :textDocument/signatureHelp #[:MAPPINGS
                                      [{:mode :i
                                        :lhs :<c-k>
                                        :rhs vim.lsp.buf.signature_help}]]
        :textDocument/typeDefinition #[:MAPPINGS
                                       [{:mode :n
                                         :lhs :<leader>gt
                                         :rhs vim.lsp.buf.type_definition}
                                        {:mode :n
                                         :lhs :<leader>pt
                                         :rhs #(mod-invoke :fsouza.lsp.locations
                                                           :preview-type-definition)}]]
        :workspace/symbol #[:MAPPINGS
                            [{:mode :n
                              :lhs :<leader>T
                              :rhs #(let [query (vim.fn.input "query：")]
                                      (when (not= query "")
                                        (mod-invoke :fsouza.lib.fuzzy
                                                    :lsp_workspace_symbols
                                                    {:lsp_query query})))}]]})

(lambda register-method [name client bufnr]
  (fn handle-attach [attach-fn]
    (attach-fn bufnr))

  (fn handle-mappings [mappings]
    (each [_ {: mode : lhs : rhs} (ipairs mappings)]
      (vim.keymap.set mode lhs rhs {:silent true :buffer bufnr})))

  (let [handler (. method-handlers name)]
    (when (and handler (client.supports_method name {: bufnr}))
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
                     (mod-invoke :fsouza.lib.popup :stylize winid)))))

(fn diag-jump [jump-fn]
  (jump-fn {:float false})
  (diag-open-float :cursor))

(fn lsp-attach [{:buf bufnr :data {:client_id client-id}}]
  (let [client (vim.lsp.get_client_by_id client-id)
        shell-post (require :fsouza.lsp.shell-post)
        mappings [{:lhs :<leader>ll :rhs #(diag-open-float :line)}
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
                  {:lhs :<c-n> :rhs #(diag-jump vim.diagnostic.goto_next)}
                  {:lhs :<c-p> :rhs #(diag-jump vim.diagnostic.goto_prev)}]]
    (patch-supports-method client)
    (shell-post.on-attach bufnr)
    (each [method _ (pairs method-handlers)]
      (register-method method client bufnr))
    (mod-invoke :fsouza.lsp.diagnostics :on-attach)
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
    (vim.diagnostic.config {:signs {:text empty-s
                                    :numhl {vim.diagnostic.severity.ERROR :DiagnosticSignError
                                            vim.diagnostic.severity.WARN :DiagnosticSignWarn
                                            vim.diagnostic.severity.INFO :DiagnosticSignInfo
                                            vim.diagnostic.severity.HINT :DiagnosticSignHint}}})))

(fn setup []
  (config-diagnostics)
  (config-log)
  (tset vim.lsp :_set_defaults #nil)
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__LspAttach
              [{:events [:LspAttach] :callback lsp-attach}]))

{: setup : register-method}
