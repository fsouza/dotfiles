;; TODO(fsouza): eventually I should bring a version of my fork of
;; nvim-lsp-compl here, or part of it. Right now, we're invoking
;; completionItem/resolve on both CompleteChanged and CompleteDone, because
;; those happen in separate places.

(import-macros {: vim-schedule : if-nil} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

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
    (set winid popup-winid)))

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
              (tset state.inflight-requests req-id true)))))))

(fn reset-state [client]
  (close)
  (each [req-id _ (pairs state.inflight-requests)]
    (vim-schedule (client.cancel_request req-id)))
  (tset state :inflight-requests {})
  (tset state :resolved-items {}))

(fn do-completeChanged [client bufnr item]
  (close)
  (when item
    (let [completion-provider (?. client :server_capabilities
                                  :completionProvider)
          completion-provider (if-nil completion-provider {})
          resolve-provider (. completion-provider :resolveProvider)]
      (if resolve-provider
          (resolve-item client bufnr item render-docs)
          (render-docs item)))))

(fn on-CompleteChanged [client bufnr]
  (let [item (?. vim :v :event :completed_item :user_data)]
    (vim-schedule (do-completeChanged client bufnr item))))

(fn do-InsertLeave [client bufnr]
  (reset-state client)
  (helpers.reset-augroup (augroup-name bufnr)))

(fn on-InsertLeave [client bufnr]
  (vim-schedule (do-InsertLeave client bufnr)))

(fn on-attach [client bufnr]
  (tset client.server_capabilities.completionProvider :triggerCharacters [])
  (tset client.resolved_capabilities :signature_help_trigger_characters [])
  (let [lsp-compl (require :lsp_compl)]
    (fn complete []
      (let [lsp-compl (require :lsp_compl)]
        (helpers.augroup (augroup-name bufnr)
                         [{:events [:CompleteChanged]
                           :targets [(string.format "<buffer=%d>" bufnr)]
                           :command (helpers.fn-cmd (partial on-CompleteChanged
                                                             client bufnr))}
                          {:events [:CompleteDone]
                           :targets [(string.format "<buffer=%d>" bufnr)]
                           :modifiers [:++once]
                           :command (helpers.fn-cmd (partial reset-state client))}
                          {:events [:InsertLeave]
                           :targets [(string.format "<buffer=%d>" bufnr)]
                           :modifiers [:++once]
                           :command (helpers.fn-cmd (partial on-InsertLeave
                                                             client bufnr))}])
        (lsp-compl.trigger_completion client bufnr)
        ""))

    (lsp-compl.attach client bufnr)
    (vim-schedule (vim.keymap.set :i :<c-x><c-o> complete
                                  {:remap false :buffer bufnr})
                  (vim.keymap.set :i :<cr>
                                  #(cr-key-for-comp-info (vim.fn.complete_info))
                                  {:remap false :buffer bufnr :expr true}))))

(fn on-detach [client bufnr]
  (helpers.reset-augroup (augroup-name bufnr))
  (when (vim.api.nvim_buf_is_valid bufnr)
    (pcall vim.keymap.del :i :<cr> {:buffer bufnr})
    (pcall vim.keymap.del :i :<c-x><c-o> {:buffer bufnr}))
  (let [lsp-compl (require :lsp_compl)]
    (lsp-compl.detach client.id bufnr)))

{: on-attach : on-detach}
