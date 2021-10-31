(import-macros {: cmd-map} :helpers)

(let [bufnr (vim.api.nvim_get_current_buf)
      helpers (require :fsouza.lib.nvim-helpers)]
  (helpers.create-mappings {:n [{:lhs "q"
                                 :rhs (cmd-map "quit")
                                 :opts {:noremap true}}]} bufnr))
