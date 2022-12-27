(import-macros {} :helpers)

(fn get-client [bufnr server-capability]
  (let [buf-clients (collect [_ client (pairs (vim.lsp.get_active_clients {: bufnr}))]
                      (if (not= (. client.server_capabilities server-capability)
                                nil)
                          (values client.name client)))]
    (or (. buf-clients :efm) (let [(_ client) (next buf-clients)]
                               client))))

{: get-client}
