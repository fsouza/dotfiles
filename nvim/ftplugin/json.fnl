(import-macros {: mod-invoke} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(let [schemastore (require :schemastore)]
  (mod-invoke :fsouza.lsp.servers :start
              {:name :json-language-server
               :cmd (node-lsp-cmd :vscode-json-language-server :--stdio)
               :settings {:format {:enable false}
                          :json {:schemas (schemastore.json.schemas)}}}))
