(let [bufnr (vim.api.nvim_get_current_buf)
      helpers (require "fsouza.lib.nvim_helpers")]
  (helpers.create-mappings {:n [{:lhs "<c-t>"
                                 :rhs (helpers.cmd-map "call dirvish#open('tabedit', 0)")}
                                {:lhs "<c-v>"
                                 :rhs (helpers.cmd-map "call dirvish#open('vsplit', 0)")}
                                {:lhs "<c-x>"
                                 :rhs (helpers.cmd-map "call dirvish#open('split', 0)")}]}
                           bufnr))
