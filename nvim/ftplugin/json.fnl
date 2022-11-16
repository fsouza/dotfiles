(import-macros {: mod-invoke} :helpers)

(let [schemastore (require :schemastore)]
  (mod-invoke :fsouza.lsp.servers :start
              {:name :json-language-server
               :cmd [:vscode-json-language-server :--stdio]
               :settings {:format {:enable false}
                          :json {:schemas (schemastore.json.schemas)}}}))
