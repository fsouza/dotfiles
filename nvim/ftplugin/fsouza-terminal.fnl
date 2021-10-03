(let [bufnr (vim.api.nvim_get_current_buf)
      helpers (require :fsouza.lib.nvim-helpers)]
  (helpers.create-mappings {:t [{:lhs "<esc><esc>"
                                 :rhs "<c-\\><c-n>"
                                 :opts {:noremap true}}]
                            :n [{:lhs "<cr>"
                                 :rhs (helpers.fn-map (fn []
                                                        (let [terminal (require :fsouza.plugin.terminal)]
                                                          (terminal.cr))))
                                 :opts {:noremap true}}]} bufnr))
