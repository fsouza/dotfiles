(import-macros {: mod-invoke : max-col} :helpers)

(fn should-skip-buffer [bufnr]
  (let [path (require :fsouza.lib.path)
        file-path (vim.api.nvim_buf_get_name bufnr)
        file-path (path.abspath file-path)]
    (not (path.isrel file-path))))

(fn formatting-params [bufnr]
  (let [et (. vim :bo bufnr :expandtab)
        tab-size (if et
                     (. vim :bo bufnr :softtabstop)
                     (. vim :bo bufnr :tabstop))
        opts {:tabSize tab-size :insertSpaces et}]
    {:textDocument {:uri (vim.uri_from_bufnr bufnr)} :options opts}))

(fn find-client [bufnr]
  (let [efm-client (. (vim.lsp.get_clients {: bufnr :name :efm}) 1)]
    (or efm-client (. (vim.lsp.get_clients {: bufnr
                                            :method :textDocument/formatting})
                      1))))

(lambda fmt [bufnr ?client ?cb]
  (let [client (or ?client (find-client bufnr))]
    (when client
      (let [(_ req-id) (client.request :textDocument/formatting
                                       (formatting-params bufnr) ?cb bufnr)]
        (values req-id #(client.cancel_request req-id))))))

(fn augroup-name [bufnr]
  (.. :lsp_autofmt_ bufnr))

(fn detach [bufnr]
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr)))

(fn autofmt-and-write [bufnr client-id]
  (macro do-autocmd []
    `(vim.api.nvim_exec_autocmds [:User]
                                 {:pattern :fsouza-LSP-autoformatted
                                  :data {: bufnr}}))
  (let [enabled (mod-invoke :fsouza.lib.autofmt :is-enabled bufnr)
        client (vim.lsp.get_client_by_id client-id)]
    (if client
        (when enabled
          (pcall #(let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)]
                    (fmt bufnr client
                         (fn [_ result]
                           (when (and (vim.api.nvim_buf_is_valid bufnr)
                                      (= changed-tick
                                         (vim.api.nvim_buf_get_changedtick bufnr)))
                             (when result
                               (vim.api.nvim_buf_call bufnr
                                                      #(do
                                                         (let [helpers (require :fsouza.lib.nvim-helpers)
                                                               hash (helpers.hash-buffer bufnr)]
                                                           (helpers.rewrite-wrap #(vim.lsp.util.apply_text_edits result
                                                                                                                 bufnr
                                                                                                                 client.offset_encoding))
                                                           (when (not= changed-tick
                                                                       (vim.api.nvim_buf_get_changedtick bufnr))
                                                             (let [new-hash (helpers.hash-buffer bufnr)
                                                                   noautocmd (= new-hash
                                                                                hash)]
                                                               (vim.cmd.update {:mods {: noautocmd}})))))))))))))
        ;; client is gone, let's detach
        (detach bufnr))
    (do-autocmd)))

(lambda attach [bufnr client-id]
  (when (not (should-skip-buffer bufnr))
    (mod-invoke :fsouza.lib.nvim-helpers :augroup (augroup-name bufnr)
                [{:events [:BufWritePost]
                  :targets [(string.format "<buffer=%d>" bufnr)]
                  :callback #(autofmt-and-write bufnr client-id)}])))

{: attach : fmt}
