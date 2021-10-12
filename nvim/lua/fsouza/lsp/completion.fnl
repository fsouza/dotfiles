(import-macros {: vim-schedule} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

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

    (lsp-compl.attach client bufnr)
    (vim-schedule (helpers.create-mappings mappings bufnr))))

(fn on-detach [bufnr]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (helpers.remove-mappings {:i [{:lhs "<cr>"}
                                  {:lhs "<c-x><c-o>"}]} bufnr)))

{: on-attach
 : on-detach}
