(import-macros {: mod-invoke} :helpers)

(let [char-code (string.byte :l)]
  (tset vim.b (.. :surround_ char-code) "[\r](\001url: \001)")
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :marksman :cmd [:marksman :server]}}))
