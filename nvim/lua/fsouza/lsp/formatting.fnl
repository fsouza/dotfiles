(import-macros {: mod-invoke : max-col} :helpers)

(fn should-skip-buffer [bufnr]
  (let [path (require :fsouza.pl.path)
        file-path (vim.api.nvim_buf_get_name bufnr)
        file-path (path.abspath file-path)]
    (not (path.isrel file-path))))

(fn formatting-params [bufnr]
  (let [sts (vim.api.nvim_get_option_value :softtabstop {:buf bufnr})
        sw (vim.api.nvim_get_option_value :shiftwidth {:buf bufnr})
        ts (vim.api.nvim_get_option_value :tabstop {:buf bufnr})
        tab-size (if (> sts 0)
                     sts
                     (if (< sts 0)
                         sw
                         ts))
        opts {:tabSize tab-size
              :insertSpaces (vim.api.nvim_get_option_value :expandtab
                                                           {:buf bufnr})}]
    {:textDocument {:uri (vim.uri_from_bufnr bufnr)} :options opts}))

(fn fmt [client bufnr cb]
  (let [client (or client
                   (mod-invoke :fsouza.lsp.clients :get-client bufnr
                               :documentFormattingProvider))]
    (when client
      (let [(_ req-id) (client.request :textDocument/formatting
                                       (formatting-params bufnr) cb bufnr)]
        (values req-id #(client.cancel_request req-id))))))

(fn autofmt-and-write [bufnr]
  (macro do-autocmd []
    `(vim.api.nvim_exec_autocmds [:User]
                                 {:pattern :fsouza-LSP-autoformatted
                                  :data {: bufnr}}))
  (let [enabled (mod-invoke :fsouza.lib.autofmt :is-enabled bufnr)]
    (if enabled
        (let [client (mod-invoke :fsouza.lsp.clients :get-client bufnr
                                 :documentFormattingProvider)]
          (if (not client)
              (error (string.format "couldn't find client for buffer %d" bufnr))
              (pcall #(let [changed-tick (vim.api.nvim_buf_get_changedtick bufnr)]
                        (fmt client bufnr
                             (fn [_ result]
                               (when (= changed-tick
                                        (vim.api.nvim_buf_get_changedtick bufnr))
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
                                                                   (vim.cmd.update {:mods {: noautocmd}})))))))
                                 (do-autocmd))))))))
        (do-autocmd))))

(fn augroup-name [bufnr]
  (.. :lsp_autofmt_ bufnr))

(fn on-attach [bufnr]
  (when (not (should-skip-buffer bufnr))
    (mod-invoke :fsouza.lib.nvim-helpers :augroup (augroup-name bufnr)
                [{:events [:BufWritePost]
                  :targets [(string.format "<buffer=%d>" bufnr)]
                  :callback #(autofmt-and-write bufnr)}]))
  (vim.keymap.set :n :<leader>f #(fmt nil bufnr) {:silent true :buffer bufnr}))

(fn on-detach [bufnr]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (pcall vim.keymap.del :n :<leader>f {:buffer bufnr}))
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr)))

{: on-attach : on-detach}
