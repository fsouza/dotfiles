(import-macros {: mod-invoke} :helpers)

;; maps bufnr to client
(local buffer-clients {})

(local langservers-org-imports-set {:gopls true})

(fn should-organize-imports [client-name]
  (and client-name (. langservers-org-imports-set client-name)))

(fn with-diagnostics [client bufnr cb]
  (fn call-cb []
    (let [diagnostics (vim.diagnostic.get bufnr {:namespace client.id})]
      (cb diagnostics)))

  (if (client.supports_method :textDocument/diagnostic)
      (let [textDocument (vim.lsp.util.make_text_document_params bufnr)]
        (client.request :textDocument/diagnostic {: textDocument} call-cb))
      (call-cb)))

(fn organize-imports-and-write [client bufnr kind]
  (let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)
        params (vim.lsp.util.make_range_params)]
    (tset params.range :start {:line 0 :character 0})
    (tset params.range :end {:line (- (vim.api.nvim_buf_line_count bufnr) 1)
                             :character 0})
    (with-diagnostics client
      bufnr
      #(let [diagnostics $1]
         (tset params :context {: diagnostics})
         (client.request :textDocument/codeAction params
                         (fn [_ actions]
                           (when (and (= changed-tick
                                         (vim.api.nvim_buf_get_changedtick bufnr))
                                      actions (not (vim.tbl_isempty actions)))
                             (let [code-action (-> actions
                                                   (vim.iter)
                                                   (: :filter #(= $1.kind kind))
                                                   (: :next))]
                               (when code-action
                                 (mod-invoke :fsouza.lsp.code-action :execute
                                             client code-action
                                             #(vim.api.nvim_buf_call bufnr
                                                                     #(vim.cmd.update))))))))))))

(lambda handle [bufnr]
  (let [{: client-id : kind} (. buffer-clients bufnr)
        client (vim.lsp.get_client_by_id client-id)]
    (if client
        (organize-imports-and-write client bufnr kind)
        (tset buffer-clients bufnr nil))))

(local setup
       (mod-invoke :fsouza.lib.nvim-helpers :once
                   #(mod-invoke :fsouza.lib.nvim-helpers :augroup
                                :fsouza__autocodeaction
                                [{:events [:User]
                                  :targets [:fsouza-LSP-autoformatted]
                                  :callback #(let [{: bufnr} (. $1 :data)]
                                               (handle bufnr))}])))

(lambda attach [bufnr client-id kind]
  (setup)
  (tset buffer-clients bufnr {: client-id : kind}))

{: attach}
