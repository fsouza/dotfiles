(import-macros {: if-nil} :helpers)

(local non-focusable-handlers {})

(fn popup-callback [err result context ...]
  (let [method context.method
        handler (if-nil (. non-focusable-handlers method) (vim.lsp.with (. vim.lsp.handlers method) {:focusable false}))]
    (tset non-focusable-handlers method handler)
    (handler err result context ...)))

(fn fzf-location-callback [_ result ctx]
  (when (and result (not (vim.tbl_isempty result)))
    (if (vim.tbl_islist result)
      (if (> (length result) 1)
        (let [fuzzy (require :fsouza.plugin.fuzzy)
              client (vim.lsp.get_client_by_id ctx.client_id)
              items (vim.lsp.util.locations_to_items result client.offset_encoding)]
          (fuzzy.send-items items "Locations"))
        (vim.lsp.util.jump_to_location (. result 1)))
      (vim.lsp.util.jump_to_location result))))

{:textDocument/declaration fzf-location-callback
 :textDocument/definition fzf-location-callback
 :textDocument/typeDefinition fzf-location-callback
 :textDocument/implementation fzf-location-callback
 :textDocument/references (fn [err result ...]
                            (let [{: filter-references} (require :fsouza.lsp.references)
                                  result (filter-references result)]
                              (fzf-location-callback err result ...)))
 :textDocument/documentHighlight (fn [_ result context]
                                   (when (not result)
                                     (lua "return"))

                                   (let [bufnr (vim.api.nvim_get_current_buf)
                                         client (vim.lsp.get_client_by_id context.client_id)]
                                     (vim.lsp.util.buf_clear_references bufnr)
                                     (vim.lsp.util.buf_highlight_references bufnr result client.offset_encoding)))
 :textDocument/hover popup-callback
 :textDocument/signatureHelp popup-callback
 :textDocument/publishDiagnostics (fn [...]
                                    (let [buf-diagnostics (require :fsouza.lsp.buf-diagnostic)]
                                      (buf-diagnostics.publish-diagnostics ...)))}
