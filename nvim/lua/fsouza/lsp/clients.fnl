(fn get-client [bufnr method-name]
  (let [buf-clients (collect [_ client (pairs (vim.lsp.get_active_clients {: bufnr}))]
                      (if (client.supports_method method-name {: bufnr})
                          (values client.name client)))]
    (or (. buf-clients :efm) (let [(_ client) (next buf-clients)]
                               client))))

{: get-client}
