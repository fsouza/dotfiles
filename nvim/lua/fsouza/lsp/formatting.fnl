(import-macros {: if-nil : mod-invoke} :helpers)

(local langservers-org-imports-set {:gopls true})

(local updates {})

(macro set-last-update [bufnr]
  `(tset updates ,bufnr (os.clock)))

(macro get-last-update [bufnr]
  `(. updates ,bufnr))

(fn should-skip-buffer [bufnr]
  (let [file-path (vim.api.nvim_buf_get_name bufnr)
        file-path (vim.fn.fnamemodify file-path ":p")
        cwd (vim.fn.getcwd)
        prefix (if (vim.endswith cwd "/")
                   cwd
                   (.. cwd "/"))
        skip (not (vim.startswith file-path prefix))]
    (when skip
      (vim.notify (string.format "[DEBUG] skipping %s because it's not in %s"
                                 file-path prefix)))
    skip))

(fn should-organize-imports [server-name]
  (. langservers-org-imports-set server-name))

(fn formatting-params [bufnr]
  (let [sts (vim.api.nvim_buf_get_option bufnr :softtabstop)
        sw (vim.api.nvim_buf_get_option bufnr :shiftwidth)
        ts (vim.api.nvim_buf_get_option bufnr :tabstop)
        tab-size (if (> sts 0)
                     sts
                     (if (< sts 0)
                         sw
                         ts))
        opts {:tabSize tab-size
              :insertSpaces (vim.api.nvim_buf_get_option bufnr :expandtab)}]
    {:textDocument {:uri (vim.uri_from_bufnr bufnr)} :options opts}))

;; if this proves to be good, I should also revisit how I keep clients in
;; codelens.fnl.
(fn get-client [bufnr]
  (let [buf-clients (collect [_ client (pairs (vim.lsp.buf_get_clients bufnr))]
                      (if (not= client.server_capabilities.documentFormattingProvider
                                nil)
                          (values client.name client)))]
    (if-nil (. buf-clients :efm) (let [(_ client) (next buf-clients)]
                                   client))))

(fn fmt [client bufnr cb]
  (let [client (if-nil client (get-client bufnr))
        (_ req-id) (client.request :textDocument/formatting
                                   (formatting-params bufnr) cb bufnr)]
    (values req-id #(client.cancel_request req-id))))

(fn organize-imports-and-write [client bufnr]
  (let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)
        params (vim.lsp.util.make_given_range_params [1 1]
                                                     [(vim.api.nvim_buf_line_count bufnr)
                                                      2147483647]
                                                     bufnr
                                                     client.offset_encoding)]
    (tset params :context
          {:diagnostics (vim.diagnostic.get bufnr {:namespace client.id})})
    (client.request :textDocument/codeAction params
                    (fn [_ actions]
                      (when (not= changed-tick
                                  (vim.api.nvim_buf_get_changedtick bufnr))
                        (lua :return))
                      (when (and actions (not (vim.tbl_isempty actions)))
                        (let [tablex (require :fsouza.tablex)
                              (_ code-action) (tablex.find_if actions
                                                              (fn [action]
                                                                (if (= action.kind
                                                                       :source.organizeImports)
                                                                    action
                                                                    false)))]
                          (when (and code-action code-action.edit)
                            (vim.api.nvim_buf_call bufnr
                                                   (fn []
                                                     (vim.lsp.util.apply_workspace_edit code-action.edit
                                                                                        client.offset_encoding)
                                                     (vim.cmd :update))))))))))

(fn autofmt-and-write [bufnr]
  (let [autofmt (require :fsouza.lib.autofmt)
        enable (autofmt.is-enabled bufnr)]
    (when (not enable)
      (lua :return))
    (let [client (get-client bufnr)]
      (if (not client)
          (error (string.format "couldn't find client for buffer %d" bufnr))
          (pcall #(let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)]
                    (fmt client bufnr
                         (fn [_ result]
                           (when (and (= changed-tick
                                         (vim.api.nvim_buf_get_changedtick bufnr))
                                      result)
                             (vim.api.nvim_buf_call bufnr
                                                    #(do
                                                       (mod-invoke :fsouza.lib.nvim-helpers
                                                                   :rewrite-wrap
                                                                   #(vim.lsp.util.apply_text_edits result
                                                                                                   bufnr
                                                                                                   client.offset_encoding))
                                                       (let [last-update (get-last-update bufnr)]
                                                         (if (and last-update
                                                                  (< (- (os.clock)
                                                                        last-update)
                                                                     0.01))
                                                             (vim.cmd "noau update")
                                                             (do
                                                               (vim.cmd :update)
                                                               (set-last-update bufnr))))
                                                       (when (should-organize-imports client.name)
                                                         (organize-imports-and-write client
                                                                                     bufnr)))))))))))))

(fn augroup-name [bufnr]
  (.. :lsp_autofmt_ bufnr))

(fn on-attach [bufnr]
  (when (should-skip-buffer bufnr)
    (lua :return))
  (mod-invoke :fsouza.lib.nvim-helpers :augroup (augroup-name bufnr)
              [{:events [:BufWritePost]
                :targets [(string.format "<buffer=%d>" bufnr)]
                :callback #(autofmt-and-write bufnr)}])
  (vim.keymap.set :n :<leader>f #(fmt nil bufnr) {:silent true :buffer bufnr}))

(fn on-detach [bufnr]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (pcall vim.keymap.del :n :<leader>f {:buffer bufnr}))
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr))
  (tset updates bufnr nil))

{: on-attach : on-detach}
