(import-macros {: if-nil} :helpers)

(fn detect-pythonPath [client]
  (let [{: detect-python-interpreter} (require :fsouza.lib.python)
        cache-dir (vim.fn.stdpath :cache)]
    (detect-python-interpreter (fn [python-path]
                                 (when python-path
                                   (tset client.config.settings.python
                                         :pythonPath python-path)
                                   (client.notify :workspace/didChangeConfiguration
                                                  {:settings client.config.settings}))))))

;; See docs for Diagnostic.Tags:
;; https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnosticTag
(fn valid-diagnostic [d]
  (let [tablex (require :fsouza.tablex)
        tags (if-nil (. d :tags) [])]
    (tablex.for-all tags #(not= $1 1))))

{: detect-pythonPath : valid-diagnostic}
