(fn is-enabled [bufnr]
  (let [helpers (require "fsouza.lib.nvim-helpers")
        (_ buf-autoformat) (pcall vim.api.nvim_buf_get_var bufnr "autoformat")]
    (helpers.if-nil buf-autoformat (partial vim.F.if_nil vim.g.autoformat true))))

(fn toggle [ns]
  (if (= (. ns :autoformat) false)
    (tset ns :autoformat true)
    (tset ns :autoformat false)))

(let [mod {:is-enabled is-enabled
           :toggle (partial toggle vim.b)
           :toggle_g (partial toggle vim.g)}]
  mod)
