(let [schemastore (require :schemastore)
      servers (require :fsouza.lsp.servers)]
  (servers.start {:config {:name :json-language-server
                           :cmd [:vscode-json-language-server :--stdio]
                           :settings {:json {:validate {:enable true}
                                             :schemas (schemastore.json.schemas)}}}}))
