(import-macros {: if-nil} :helpers)

(fn is-enabled [bufnr]
  (let [(defined buf-autoformat) (pcall vim.api.nvim_buf_get_var bufnr
                                        :autoformat)
        buf-autoformat (if defined buf-autoformat nil)]
    (if-nil buf-autoformat vim.g.autoformat true)))

(fn toggle [ns]
  (if (= (. ns :autoformat) false)
      (tset ns :autoformat true)
      (tset ns :autoformat false)))

(let [mod {: is-enabled :toggle #(toggle vim.b) :toggle_g #(toggle vim.g)}]
  mod)
