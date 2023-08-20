(import-macros {: mod-invoke} :helpers)

; used to store information about ongoing completion, gets reset everytime we
; exit "completion mode".
(local state {:inflight-requests {} :rendered-docs {}})

(var winid nil)

(var doc-bufnr nil)

(fn cr-key-for-comp-info [comp-info]
  (if (= comp-info.mode "")
      :<cr>
      (if (and (= comp-info.pum_visible 1) (= comp-info.selected -1))
          :<c-e><cr>
          :<cr>)))

(fn item-documentation [item]
  (match (type item.documentation)
    :table item.documentation
    _ {:kind :plaintext :value (vim.trim (or item.documentation ""))}))

(fn popup-contents [item]
  (let [item-key (vim.inspect item)
        docs (. state.rendered-docs item-key)]
    (if docs
        docs
        (let [doc-lines []
              detail (or (?. item :detail) "")
              detail (vim.trim detail)
              documentation (item-documentation item)]
          (when (not= detail "")
            (table.insert doc-lines {:kind :plaintext :value detail}))
          (when (not= documentation.value "")
            (table.insert doc-lines documentation.value))
          (let [docs (vim.lsp.util.convert_input_to_markdown_lines doc-lines)]
            (tset state.rendered-docs item-key docs)
            docs)))))

(fn calc-max-width [max-width starting-pos right]
  (let [cols vim.o.columns
        available-space (if right
                            (- cols starting-pos 2)
                            (- starting-pos 2))]
    (math.min max-width available-space)))

(macro valid-winid []
  `(and winid (vim.api.nvim_win_is_valid winid)))

(macro valid-doc-bufnr []
  `(and doc-bufnr (vim.api.nvim_buf_is_valid doc-bufnr)))

(fn show-or-update-popup [contents]
  (when (not= (vim.fn.pumvisible) 0)
    (let [{: row : col : width : scrollbar} (vim.fn.pum_getpos)
          scrollbar (if scrollbar 1 0)
          end-col (+ col width scrollbar)
          max-width (calc-max-width 100 end-col true)
          right (> max-width 25)
          max-width (if right max-width (calc-max-width 100 col false))
          left-col (if right end-col nil)
          right-col (if right nil col)
          (popup-winid popup-bufnr) (mod-invoke :fsouza.lib.popup :open
                                                {:lines contents
                                                 :enter false
                                                 :type-name :completion-doc
                                                 :markdown true
                                                 : row
                                                 :col left-col
                                                 : right-col
                                                 :relative :editor
                                                 : max-width
                                                 :update-if-exists true})]
      (set winid popup-winid)
      (set doc-bufnr popup-bufnr))))

(fn augroup-name [bufnr]
  (string.format "fsouza-completion-%d" bufnr))

(fn close []
  (when (valid-winid)
    (vim.api.nvim_win_close winid false))
  (when (valid-doc-bufnr)
    (vim.api.nvim_buf_delete doc-bufnr {:force true}))
  (set winid nil)
  (set doc-bufnr nil))

(fn render-docs [item]
  (let [docs (popup-contents item)]
    (when (> (length docs) 0)
      (vim.schedule #(show-or-update-popup docs)))))

(fn reset-state []
  (close)
  (each [req-id client (pairs state.inflight-requests)]
    (vim.schedule #(client.cancel_request req-id)))
  (tset state :inflight-requests {})
  (tset state :rendered-docs {}))

(fn do-CompleteChanged [bufnr user-data]
  (if user-data.item
      (mod-invoke :lsp_compl :resolve_item user-data render-docs)
      (close)))

(fn on-CompleteChanged [bufnr]
  (let [user-data (or (?. vim :v :event :completed_item :user_data) {})]
    (vim.schedule #(do-CompleteChanged bufnr user-data))))

(fn do-InsertLeave [bufnr]
  (reset-state)
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr)))

(fn on-InsertLeave [bufnr]
  (vim.schedule #(do-InsertLeave bufnr)))

(fn on-attach [bufnr]
  (let [lsp-compl (require :lsp_compl)]
    (fn complete []
      (mod-invoke :fsouza.lib.nvim-helpers :augroup (augroup-name bufnr)
                  [{:events [:CompleteChanged]
                    :targets [(string.format "<buffer=%d>" bufnr)]
                    :callback #(on-CompleteChanged bufnr)}
                   {:events [:CompleteDone]
                    :targets [(string.format "<buffer=%d>" bufnr)]
                    :once true
                    :callback reset-state}
                   {:events [:InsertLeave]
                    :targets [(string.format "<buffer=%d>" bufnr)]
                    :once true
                    :callback #(on-InsertLeave bufnr)}])
      (lsp-compl.trigger_completion bufnr)
      "")

    (lsp-compl.attach bufnr)
    (vim.keymap.set :i :<c-x><c-o> complete {:remap false :buffer bufnr})
    (vim.keymap.set :i :<cr> #(cr-key-for-comp-info (vim.fn.complete_info))
                    {:remap false :buffer bufnr :expr true})))

{: on-attach}
