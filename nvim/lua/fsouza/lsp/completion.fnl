(import-macros {: vim-schedule : if-nil} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(var winid nil)

(fn cr-key-for-comp-info [comp-info]
  (if (= comp-info.mode "")
    "<cr>"
    (if (and (= comp-info.pum_visible 1) (= comp-info.selected -1))
      "<c-e><cr>"
      "<cr>")))

(local cr-cmd
  (helpers.ifn-map
    (fn []
      (let [r (cr-key-for-comp-info (vim.fn.complete_info))]
        (vim.api.nvim_replace_termcodes r true false true)))))

(fn item-documentation [item]
  (match (type item.documentation)
    "table" item.documentation
    _ {:kind "plaintext"
       :value (vim.trim (if-nil item.documentation ""))}))

(fn popup-contents [item]
  (let [doc-lines []
        detail (if-nil (?. item :detail) "")
        detail (vim.trim detail)
        documentation (item-documentation item)]
    (when (not= detail "")
      (table.insert doc-lines {:kind "plaintext"
                               :value detail}))

    (when (not= documentation.value "")
      (table.insert doc-lines documentation.value))

    (vim.lsp.util.convert_input_to_markdown_lines doc-lines)))

(fn show-popup [contents]
  (let [popup (require :fsouza.lib.popup)
        {: row
         : col
         : width} (vim.fn.pum_getpos)
        (popup-winid _) (popup.open {:lines contents
                                     :enter false
                                     :type-name "completion-doc"
                                     :row row
                                     :col (+ col width)
                                     :relative "editor"})]
    (set winid popup-winid)))

(fn augroup-name [bufnr]
  (string.format "fsouza-completion-%d" bufnr))

(fn close []
  (when winid
    (vim.api.nvim_win_close winid false)
    (set winid nil)))

(fn on-CompleteChanged []
  (vim.schedule close)
  (let [item (?. vim :v :event :completed_item :user_data)]
    (when item
      (let [docs (popup-contents item)]
        (when (> (length docs) 0)
          (vim-schedule (show-popup docs)))))))

(fn on-attach [client bufnr]
  (tset client.server_capabilities.completionProvider :triggerCharacters [])
  (tset client.resolved_capabilities :signature_help_trigger_characters [])

  (let [lsp-compl (require "lsp_compl")
        complete-cmd (helpers.ifn-map (fn []
                                          (lsp-compl.trigger_completion)
                                          ""))
          mappings {:i [{:lhs "<cr>"
                         :rhs cr-cmd
                         :opts {:noremap true}}
                        {:lhs "<c-x><c-o>"
                         :rhs complete-cmd
                         :opts {:noremap true}}]}]

    (helpers.augroup (augroup-name bufnr) [{:events ["CompleteChanged"]
                                            :targets [(string.format "<buffer=%d>" bufnr)]
                                            :command (helpers.fn-cmd on-CompleteChanged)}
                                           {:events ["CompleteDone"]
                                            :targets [(string.format "<buffer=%d>" bufnr)]
                                            :command (helpers.fn-cmd close)}])

    (lsp-compl.attach client bufnr)
    (vim-schedule (helpers.create-mappings mappings bufnr))))

(fn on-detach [bufnr]
  (helpers.reset-augroup (augroup-name bufnr))

  (when (vim.api.nvim_buf_is_valid bufnr)
    (helpers.remove-mappings {:i [{:lhs "<cr>"}
                                  {:lhs "<c-x><c-o>"}]} bufnr)))

{: on-attach
 : on-detach}
