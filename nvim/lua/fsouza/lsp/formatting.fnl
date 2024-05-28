(local buffer-registry {})

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
  (let [{: client-name} (or (. buffer-registry bufnr) {})
        client-name (or client-name "")]
    (or (. (vim.lsp.get_clients {: bufnr :name client-name}) 1)
        (. (vim.lsp.get_clients {: bufnr :name :efm}) 1)
        (. (vim.lsp.get_clients {: bufnr :method :textDocument/formatting}) 1))))

(lambda fmt [bufnr ?client ?cb]
  (let [client (or ?client (find-client bufnr))]
    (when client
      (let [(_ req-id) (client.request :textDocument/formatting
                                       (formatting-params bufnr) ?cb bufnr)]
        (values req-id #(client.cancel_request req-id))))))

(fn augroup-name [bufnr]
  (.. :lsp_autofmt_ bufnr))

(fn detach [bufnr]
  (let [nvim-helpers (require :fsouza.lib.nvim-helpers)]
    (nvim-helpers.reset-augroup (augroup-name bufnr)))
  (tset buffer-registry bufnr nil))

(fn autofmt-and-write [bufnr client-id]
  (macro do-autocmd []
    `(vim.api.nvim_exec_autocmds [:User]
                                 {:pattern :fsouza-LSP-autoformatted
                                  :data {: bufnr}}))
  (let [enabled (let [autofmt (require :fsouza.lib.autofmt)]
                  (autofmt.is-enabled bufnr))
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
                                                               (vim.cmd.update {:mods {: noautocmd}})))))))))
                         (do-autocmd)))))
        ;; client is gone, let's detach
        (do
          (detach bufnr)
          (do-autocmd)))))

(lambda attach [bufnr client-id ?priority]
  (let [client (vim.lsp.get_client_by_id client-id)
        {:priority current-priority} (or (. buffer-registry bufnr)
                                         {:priority 0})
        priority (or ?priority 1)
        {: augroup} (require :fsouza.lib.nvim-helpers)]
    (when (and client (not (should-skip-buffer bufnr))
               (> priority current-priority))
      (augroup (augroup-name bufnr)
               [{:events [:BufWritePost]
                 :targets [(string.format "<buffer=%d>" bufnr)]
                 :callback #(autofmt-and-write bufnr client-id)}])
      (tset buffer-registry bufnr {:client-name client.name : priority}))))

{: attach : fmt}
