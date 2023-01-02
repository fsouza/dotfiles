(import-macros {: mod-invoke : custom-surround} :helpers)

(do
  (custom-surround :l  "[\r](\001url: \001)")
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :marksman :cmd [:marksman :server]}}))
