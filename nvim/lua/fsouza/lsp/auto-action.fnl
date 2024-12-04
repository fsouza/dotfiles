;; maps bufnr to client
(local buffer-clients {})

(local langservers-org-imports-set {:gopls true})

(fn should-organize-imports [client-name]
  (and client-name (. langservers-org-imports-set client-name)))

(fn with-diagnostics [client bufnr cb]
  (fn call-cb []
    (let [diagnostics (vim.diagnostic.get bufnr {:namespace client.id})]
      (cb diagnostics)))

  (if (client:supports_method :textDocument/diagnostic)
      (let [textDocument (vim.lsp.util.make_text_document_params bufnr)]
        (client:request :textDocument/diagnostic {: textDocument} call-cb))
      (call-cb)))

(fn execute [client action cb ?resolved]
  (if (or action.edit (= (type action.command) :table))
      (do
        (when action.edit
          (vim.lsp.util.apply_workspace_edit action.edit client.offset_encoding))
        (when (= (type action.command) :table)
          (vim.lsp.buf.execute_command action.command))
        (cb))
      (not ?resolved)
      (client:request :codeAction/resolve action
                      (fn [_ resolved-action]
                        (when resolved-action
                          (execute client resolved-action cb true))))
      (and action.command action.arguments)
      (do
        (vim.lsp.buf.execute_command action)
        (cb))))

(fn organize-imports-and-write [client bufnr kind]
  (let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)
        params (vim.lsp.util.make_range_params 0 client.offset_encoding)]
    (tset params.range :start {:line 0 :character 0})
    (tset params.range :end {:line (- (vim.api.nvim_buf_line_count bufnr) 1)
                             :character 0})
    (with-diagnostics client
      bufnr
      #(let [diagnostics $1]
         (tset params :context {: diagnostics})
         (client:request :textDocument/codeAction params
                         (fn [_ actions]
                           (when (and (= changed-tick
                                         (vim.api.nvim_buf_get_changedtick bufnr))
                                      actions (not (vim.tbl_isempty actions)))
                             (let [code-action (-> actions
                                                   (vim.iter)
                                                   (: :filter #(= $1.kind kind))
                                                   (: :next))]
                               (when code-action
                                 (execute client code-action
                                          #(vim.api.nvim_buf_call bufnr
                                                                  #(vim.cmd.update))))))))))))

(fn handle [bufnr]
  (let [{: client-id : kind} (. buffer-clients bufnr)
        client (vim.lsp.get_client_by_id client-id)]
    (if client
        (organize-imports-and-write client bufnr kind)
        (tset buffer-clients bufnr nil))))

(local setup
       (let [nvim-helpers (require :fsouza.lib.nvim-helpers)]
         (nvim-helpers.once #(nvim-helpers.augroup :fsouza__autocodeaction
                                                   [{:events [:User]
                                                     :targets [:fsouza-LSP-autoformatted]
                                                     :callback #(let [{: bufnr} (. $1
                                                                                   :data)]
                                                                  (when (. buffer-clients
                                                                           bufnr)
                                                                    (handle bufnr)))}]))))

(fn attach [bufnr client-id kind]
  (setup)
  (tset buffer-clients bufnr {: client-id : kind}))

{: attach}
