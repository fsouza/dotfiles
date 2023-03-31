(import-macros {: mod-invoke} :helpers)

(fn add-to-efm [lang-id bufnr]
  (let [efm-formatters (require :fsouza.lib.efm-formatters)]
    (efm-formatters.get-prettierd #(let [prettierd $1]
                                     (efm-formatters.get-eslintd #(let [tools $1]
                                                                    (table.insert tools
                                                                                  prettierd)
                                                                    (vim.schedule #(mod-invoke :fsouza.lsp.servers.efm
                                                                                               :add
                                                                                               bufnr
                                                                                               lang-id
                                                                                               tools))))))))

(fn make-tss-test-check [ext]
  (let [pats [(.. "%.spec%." ext) (.. "%.test%." ext) (.. :/__tests__/)]]
    (fn [fname]
      (each [_ pat (ipairs pats)]
        (when (not= (string.find fname pat) nil)
          (lua "return true")))
      false)))

(fn start-typescript-language-server [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               :config {:name :typescript-language-server
                        :cmd [:typescript-language-server :--stdio]}
               :cb #(let [{: register-test-checker} (require :fsouza.lsp.references)
                          exts [:js :jsx :ts :tsx]]
                      (each [_ ext (ipairs exts)]
                        (register-test-checker (.. "." ext) ext
                                               (make-tss-test-check ext))))}))

(fn start [lang-id]
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (add-to-efm lang-id bufnr)
    (start-typescript-language-server bufnr)))

{: start}
