(import-macros {: mod-invoke} :helpers)

(let [log-buffers {}]
  (fn setup-buffer [client-name]
    (let [bufnr (vim.api.nvim_create_buf false true)]
      (vim.api.nvim_buf_set_name bufnr (.. :lsp-logs- client-name))
      (tset log-buffers client-name bufnr)
      bufnr))

  (fn get-buffer [client-id]
    (let [client (vim.lsp.get_client_by_id client-id)]
      (if client
          (or (. log-buffers client.name) (setup-buffer client.name))
          nil)))

  (fn handle [err result ctx]
    (let [{:client_id client-id} ctx
          bufnr (get-buffer client-id)]
      (when bufnr
        (vim.api.nvim_buf_set_lines bufnr -1 -1 false
                                    (vim.split result.message "\n"
                                               {:plain true})))))

  (fn show-logs- [client-name]
    (let [bufnr (. log-buffers client-name)]
      (when bufnr
        (vim.api.nvim_set_current_buf bufnr))))

  (fn find-client []
    (let [tablex (require :fsouza.pl.tablex)
          client-names (->> (vim.lsp.get_active_clients) (tablex.map #$1.name))]
      (mod-invoke :fsouza.lib.fuzzy :send-items client-names "LSP Client"
                  #(let [[client-name] $1]
                     (vim.schedule #(show-logs- client-name))))))

  (lambda show-logs [?client-name]
    (if ?client-name
        (show-logs- ?client-name)
        (find-client)))

  (fn clean-logs [client-name]
    (let [bufnr (. log-buffers client-name)]
      (when bufnr
        (vim.api.nvim_buf_delete bufnr {:force true})
        (tset log-buffers client-name nil))))

  {: handle : show-logs : clean-logs})
