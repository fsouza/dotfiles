(let [bufnr (vim.api.nvim_get_current_buf)
      helpers (require "fsouza.lib.nvim-helpers")]
  (helpers.create-mappings {:n [{:lhs "q"
                                 :rhs (helpers.cmd-map "quitall")
                                 :opts {:noremap true}}]} bufnr))
