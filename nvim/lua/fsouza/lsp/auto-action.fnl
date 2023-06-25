(import-macros {: mod-invoke} :helpers)

;; maps bufnr to client
(local buffer-clients {})

(local langservers-org-imports-set {:gopls true :jdtls true})

(fn should-organize-imports [client-name]
  (and client-name (. langservers-org-imports-set client-name)))

(fn organize-imports-and-write [client bufnr]
  (let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)
        params (vim.lsp.util.make_range_params)]
    (tset params :context
          {:diagnostics (vim.diagnostic.get bufnr {:namespace client.id})})
    (tset params.range :start {:line 0 :character 0})
    (tset params.range :end {:line (- (vim.api.nvim_buf_line_count bufnr) 1)
                             :character 0})
    (client.request :textDocument/codeAction params
                    (fn [_ actions]
                      (when (and (= changed-tick
                                    (vim.api.nvim_buf_get_changedtick bufnr))
                                 actions (not (vim.tbl_isempty actions)))
                        (let [(_ code-action) (mod-invoke :fsouza.pl.tablex
                                                          :find_if actions
                                                          (fn [action]
                                                            (if (= action.kind
                                                                   :source.organizeImports)
                                                                action
                                                                false)))]
                          (when code-action
                            (vim.api.nvim_buf_call bufnr
                                                   (fn []
                                                     (mod-invoke :fsouza.lsp.code-action
                                                                 :execute client
                                                                 code-action)
                                                     (vim.cmd.update))))))))))

(lambda handle [bufnr]
  (let [client-id (. buffer-clients bufnr)
        client (vim.lsp.get_client_by_id client-id)]
    (if client
        (organize-imports-and-write client bufnr)
        (tset buffer-clients bufnr nil))))

(local setup
       (mod-invoke :fsouza.lib.nvim-helpers :once
                   #(mod-invoke :fsouza.lib.nvim-helpers :augroup
                                :fsouza__autoorganizeimports
                                [{:events [:User]
                                  :targets [:fsouza-LSP-autoformatted]
                                  :callback #(let [{: bufnr} (. $1 :data)]
                                               (handle bufnr))}])))

(fn attach [bufnr client-id]
  (setup)
  (tset buffer-clients bufnr client-id))

{: attach}
