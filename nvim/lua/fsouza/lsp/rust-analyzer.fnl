(import-macros {: if-nil : mod-invoke} :helpers)

;; See docs for Diagnostic.Tags:
;; https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnosticTag
(fn valid-diagnostic [d]
  (let [severity (if-nil (. d :severity) 0)]
    (print severity)
    (< severity 4)))

{: valid-diagnostic}
