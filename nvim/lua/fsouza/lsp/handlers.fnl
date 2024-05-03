(import-macros {: mod-invoke} :helpers)

(local non-focusable-handlers {})

(fn popup-callback [err result context ...]
  (let [method context.method
        handler (or (. non-focusable-handlers method)
                    (vim.lsp.with (. vim.lsp.handlers method)
                      {:focusable false}))]
    (tset non-focusable-handlers method handler)
    (let [(_ winid) (handler err result context ...)]
      (when winid
        (mod-invoke :fsouza.lib.popup :stylize winid)))))

(fn fzf-location-callback [_ result ctx]
  (when (and result (not (vim.tbl_isempty result)))
    (let [client (vim.lsp.get_client_by_id ctx.client_id)]
      (if (vim.tbl_islist result)
          (if (> (length result) 1)
              (let [items (vim.lsp.util.locations_to_items result
                                                           client.offset_encoding)]
                (mod-invoke :fsouza.lib.fuzzy :send-lsp-items items :Locations))
              (vim.lsp.util.jump_to_location (. result 1)
                                             client.offset_encoding))
          (vim.lsp.util.jump_to_location result client.offset_encoding)))))

{:textDocument/declaration fzf-location-callback
 :textDocument/definition fzf-location-callback
 :textDocument/typeDefinition fzf-location-callback
 :textDocument/implementation fzf-location-callback
 :textDocument/references (fn [err result ...]
                            (let [result (mod-invoke :fsouza.lsp.references
                                                     :filter-references result)]
                              (fzf-location-callback err result ...)))
 :textDocument/documentHighlight (fn [_ result context]
                                   (when result
                                     (let [bufnr (vim.api.nvim_get_current_buf)
                                           client (vim.lsp.get_client_by_id context.client_id)]
                                       (vim.lsp.util.buf_clear_references bufnr)
                                       (vim.lsp.util.buf_highlight_references bufnr
                                                                              result
                                                                              client.offset_encoding))))
 :textDocument/hover popup-callback
 :textDocument/signatureHelp popup-callback
 :textDocument/publishDiagnostics #(mod-invoke :fsouza.lsp.buf-diagnostic
                                               :publish-diagnostics $...)
 :window/logMessage #(mod-invoke :fsouza.lsp.log-message :handle $...)}
