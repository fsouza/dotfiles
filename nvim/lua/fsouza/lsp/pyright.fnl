(import-macros {: if-nil : mod-invoke} :helpers)

(fn detect-pythonPath [client]
  (mod-invoke :fsouza.lib.python :detect-python-interpreter
              (fn [python-path]
                (when python-path
                  (tset client.config.settings.python :pythonPath python-path)
                  (client.notify :workspace/didChangeConfiguration
                                 {:settings client.config.settings})))))

;; See docs for Diagnostic.Tags:
;; https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnosticTag
(fn valid-diagnostic [d]
  (let [tags (if-nil (. d :tags) [])]
    (mod-invoke :fsouza.tablex :for-all tags #(not= $1 1))))

{: detect-pythonPath : valid-diagnostic}
