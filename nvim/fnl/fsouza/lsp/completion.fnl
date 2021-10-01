(local helpers (require "fsouza.lib.nvim_helpers"))

(local load-cmp (helpers.once (fn []
                                (vim.cmd "packadd nvim-cmp")
                                (let [cmp-nvim-lsp (require "cmp_nvim_lsp")]
                                  (cmp-nvim-lsp.setup)
                                  (require "cmp")))))

(fn setup [bufnr]
  (let [cmp (load-cmp)
        cmp-config (require "cmp.config")]
    (cmp-config.set_buffer {:completion {:autocomplete false}
                            :mapping {:<c-y> (cmp.mapping.confirm {:behavior cmp.ConfirmBehavior.Replace
                                                                   :select true})}
                            :snippet {:expand (fn [args]
                                                (let [luasnip (require "luasnip")]
                                                  (luasnip.lsp_expand args.body)))}
                            :sources [{:name "nvim_lsp"}]
                            :documentation {:border "none"
                                            :winhighlight "Normal:CmpDocumentation"}
                            :preselect cmp.PreselectMode.None
                            :formatting {:format (fn [entry vim-item]
                                                   (let [menu (if (= entry.source.name "nvim_lsp")
                                                                "LSP"
                                                                entry.source.name)]
                                                     (tset vim-item :menu (string.format "「%s」" menu))
                                                     vim-item))}}
                            bufnr)))

(fn cr-key-for-comp-info [comp-info]
  (if (= comp-info.mode "")
    "<cr>"
    (if (and (= comp-info.pum_visible 1) (= comp_info.selected -1))
      "<c-e><cr>"
      "<cr>")))

(local cr-cmd
  (helpers.ifn-map
    (fn []
      (let [r (cr-key-for-comp-info (vim.fn.complete_info))]
        (vim.api.nvim_replace_termcodes r true false true)))))

(fn on-attach [bufnr]
  (setup bufnr)

  (let [complete-cmd (helpers.ifn-map (fn []
                                        (let [cmp (load-cmp)]
                                          (cmp.complete)
                                          "")))
        color (require "fsouza.color")]

    (color.set-popup-cb
      (fn []
        (let [winids (vim.api.nvim_list_wins)]
          (each [_ winid (ipairs winids)]
            (when (string.match (vim.api.nvim_win_get_option winid "winhighlight") "CmpDocumentation")
              (lua "return winid"))))))

    (let [mappings {:i [{:lhs "<cr>"
                         :rhs cr-cmd
                         :opts {:noremap true}}
                        {:lhs "<c-x><c-o>"
                         :rhs complete-cmd
                         :opts {:noremap true}}]}]
      (vim.schedule (partial helpers.create-mappings mappings bufnr)))))

(fn on-detach [bufnr]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (helpers.remove-mappings {:i [{:lhs "<cr>"}
                                  {:lhs "<c-x><c-o>"}]} bufnr))

  (let [cmp-config (require "cmp.config")]
    (tset cmp-config.buffers bufnr nil)))

{:on-attach on-attach
 :on-detach on-detach}
