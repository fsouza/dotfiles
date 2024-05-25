(import-macros {: mod-invoke} :helpers)

(let [ols (vim.fs.joinpath _G.cache-dir :langservers :ols :ols)]
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :ols
                        :cmd [ols]
                        :init_options {:enable_format true
                                       :enable_hover true
                                       :enable_references true}}
               :opts {:autofmt true}}))
