(import-macros {: mod-invoke} :helpers)

(let [path (require :fsouza.pl.path)
      jdtls (path.join cache-dir :langservers :jdtls :bin :jdtls)
      config-dir (path.join cache-dir :jdtls)
      data-dir (path.join data-dir :jdtls)]
  (mod-invoke :fsouza.lsp.servers :start
              {:name :jdtls
               :cmd [jdtls :-configuration config-dir :-data data-dir]}))
