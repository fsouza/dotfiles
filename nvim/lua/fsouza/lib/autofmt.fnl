(lambda is-enabled [bufnr]
  (let [buf-autoformat (. vim :b bufnr :autoformat)]
    (if (not= buf-autoformat nil) buf-autoformat
        (not= vim.g.autoformat nil) vim.g.autoformat
        true)))

(lambda toggle [ns]
  (if (= (. ns :autoformat) false)
      (tset ns :autoformat true)
      (tset ns :autoformat false)))

(let [mod {: is-enabled :toggle #(toggle vim.b) :toggle_g #(toggle vim.g)}]
  mod)
