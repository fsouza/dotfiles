(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

; used to store information about ongoing completion, gets reset everytime we
; exit "completion mode".
(local state {:inflight-requests {} :resolved-items {}})

(var winid nil)

(fn cr-key-for-comp-info [comp-info]
  (if (= comp-info.mode "") :<cr>
      (if (and (= comp-info.pum_visible 1) (= comp-info.selected -1))
          :<c-e><cr> :<cr>)))

(fn item-documentation [item]
  (match (type item.documentation)
    :table item.documentation
    _ {:kind :plaintext :value (vim.trim (if-nil item.documentation ""))}))

(fn popup-contents [item]
  (let [doc-lines []
        detail (if-nil (?. item :detail) "")
        detail (vim.trim detail)
        documentation (item-documentation item)]
    (when (not= detail "")
      (table.insert doc-lines {:kind :plaintext :value detail}))
    (when (not= documentation.value "")
      (table.insert doc-lines documentation.value))
    (vim.lsp.util.convert_input_to_markdown_lines doc-lines)))

(fn calc-max-width [max-width starting-pos right]
  (let [cols vim.o.columns
        available-space (if right
                            (- cols starting-pos 2)
                            (- starting-pos 2))]
    (math.min max-width available-space)))

(fn show-popup [contents]
  (when (not= (vim.fn.pumvisible) 0)
    (let [popup (require :fsouza.lib.popup)
          {: row : col : width : scrollbar} (vim.fn.pum_getpos)
          scrollbar (if scrollbar 1 0)
          end-col (+ col width scrollbar)
          max-width (calc-max-width 100 end-col true)
          right (> max-width 25)
          max-width (if right max-width (calc-max-width 100 col false))
          left-col (if right end-col nil)
          right-col (if right nil col)
          (popup-winid _) (popup.open {:lines contents
                                       :enter false
                                       :type-name :completion-doc
                                       :markdown true
                                       : row
                                       :col left-col
                                       : right-col
                                       :relative :editor
                                       : max-width})]
      (set winid popup-winid))))

(fn augroup-name [bufnr]
  (string.format "fsouza-completion-%d" bufnr))

(fn close []
  (when (and winid (vim.api.nvim_win_is_valid winid))
    (vim.api.nvim_win_close winid false))
  (set winid nil))

(fn render-docs [item]
  (let [docs (popup-contents item)]
    (when (> (length docs) 0)
      (vim-schedule (show-popup docs)))))

(fn resolve-item [client bufnr item cb]
  (var request-id nil)
  (let [item-key (if-nil item.sortText item.label)]
    (when item-key
      (fn on-resolve [err item]
        (when (not err)
          (tset state.resolved-items item-key item)
          (cb item))
        (if request-id
            (tset state.inflight-requests request-id nil)))

      (let [resolved-item (. state.resolved-items item-key)]
        (if resolved-item
            (cb resolved-item)
            (let [(_ req-id) (client.request :completionItem/resolve item
                                             on-resolve bufnr)]
              (when req-id
                (set request-id req-id)
                (tset state.inflight-requests req-id client))))))))

(fn reset-state []
  (close)
  (each [req-id client (pairs state.inflight-requests)]
    (vim-schedule (client.cancel_request req-id)))
  (tset state :inflight-requests {})
  (tset state :resolved-items {}))

(fn do-completeChanged [bufnr item client-id]
  (close)
  (when item
    (let [client (vim.lsp.get_client_by_id client-id)
          completion-provider (?. client :server_capabilities
                                  :completionProvider)
          completion-provider (if-nil completion-provider {})
          resolve-provider (. completion-provider :resolveProvider)]
      (if resolve-provider
          (resolve-item client bufnr item render-docs)
          (render-docs item)))))

(fn on-CompleteChanged [bufnr]
  (let [user-data (if-nil (?. vim :v :event :completed_item :user_data) {})
        {: item :client_id client-id} user-data]
    (vim-schedule (do-completeChanged bufnr item client-id))))

(fn do-InsertLeave [bufnr]
  (reset-state)
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr)))

(fn on-InsertLeave [bufnr]
  (vim-schedule (do-InsertLeave bufnr)))

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
    (vim-schedule (vim.keymap.set :i :<c-x><c-o> complete
                                  {:remap false :buffer bufnr})
                  (vim.keymap.set :i :<cr>
                                  #(cr-key-for-comp-info (vim.fn.complete_info))
                                  {:remap false :buffer bufnr :expr true}))))

(fn on-detach [bufnr]
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr))
  (when (vim.api.nvim_buf_is_valid bufnr)
    (pcall vim.keymap.del :i :<cr> {:buffer bufnr})
    (pcall vim.keymap.del :i :<c-x><c-o> {:buffer bufnr}))
  (let [lsp-compl (require :lsp_compl)]
    (lsp-compl.detach bufnr)))

{: on-attach : on-detach}
