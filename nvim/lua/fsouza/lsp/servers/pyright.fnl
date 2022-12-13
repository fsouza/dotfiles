(import-macros {: if-nil : mod-invoke} :helpers)

;; See docs for Diagnostic.Tags:
;; https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnosticTag
(lambda valid-diagnostic [d]
  (let [tags (if-nil (. d :tags) [])]
    (mod-invoke :fsouza.pl.tablex :for-all tags #(not= $1 1))))

{: valid-diagnostic}
