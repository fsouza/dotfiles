(import-macros {: mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(fn setup []
  (mod-invoke :fsouza.lsp.servers :start {:name :ocaml-lsp :cmd [:ocamllsp]}
              #(mod-invoke :fsouza.lsp.servers :patterns-with-fallback
                           [:.merlin])))

{: setup}
