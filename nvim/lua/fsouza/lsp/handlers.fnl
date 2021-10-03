(import-macros {: if-nil} :helpers)

(local non-focusable-handlers {})

(fn popup-callback [err result context ...]
  (let [method context.method
        handler (if-nil (. non-focusable-handlers method) (vim.lsp.with (. vim.lsp.handlers method) {:focusable false}))
        color (require :fsouza.color)]
    (tset non-focusable-handlers method handler)
    (handler err result context ...)
    (each [_ winid (ipairs (vim.api.nvim_list_wins))]
      (when (pcall vim.api.nvim_win_get_var winid method)
        (color.set-popup-winid winid)))))

(fn fzf-location-callback [_ result]
  (when (and result (not (vim.tbl_isempty result)))
    (if (vim.tbl_islist result)
      (if (> (length result) 1)
        (let [fuzzy (require :fsouza.plugin.fuzzy)
              items (vim.lsp.util.locations_to_items result)]
          (fuzzy.send-items items "Locations"))
        (vim.lsp.util.jump_to_location (. result 1)))
      (vim.lsp.util.jump_to_location result))))

{:textDocument/declaration fzf-location-callback
:textDocument/definition fzf-location-callback
:textDocument/typeDefinition fzf-location-callback
:textDocument/implementation fzf-location-callback
:textDocument/references (fn [err result ...]
                           (var result result)
                           (when (vim.tbl_islist result)
                             (let [tablex (require :fsouza.tablex)
                                   (lineno _) (unpack (vim.api.nvim_win_get_cursor 0))
                                   lineno (- lineno 1)]
                               (set result (tablex.filter result (fn [v]
                                                                   (not= v.range.start.line lineno))))))
                           (fzf-location-callback err result ...))
:textDocument/documentHighlight (fn [_ result]
                                  (when (not result)
                                    (lua "return"))

                                  (let [bufnr (vim.api.nvim_get_current_buf)]
                                    (vim.lsp.util.buf_clear_references bufnr)
                                    (vim.lsp.util.buf_highlight_references bufnr result)))
:textDocument/hover popup-callback
:textDocument/signatureHelp popup-callback
:textDocument/publishDiagnostics (fn [...]
                                   (let [buf-diagnostics (require :fsouza.lsp.buf-diagnostic)]
                                     (buf-diagnostics.publish-diagnostics ...)))}
