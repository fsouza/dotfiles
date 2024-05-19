(import-macros {: mod-invoke} :helpers)

;; See docs for Diagnostic.Tags:
;; https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnosticTag
(lambda valid-diagnostic [d]
  (let [severity (or d.severity 1)]
    (and (< severity 2) (-> d
                            (. :tags)
                            (or [])
                            (vim.iter)
                            (: :all #(not= $1 1))))))

{: valid-diagnostic}
