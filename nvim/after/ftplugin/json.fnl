(import-macros {: mod-invoke} :helpers)

(let [schemastore (require :schemastore)]
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :json-language-server
                        :cmd [:vscode-json-language-server :--stdio]
                        :settings {:json {:validate {:enable true}
                                          :schemas (schemastore.json.schemas)}}}}))
