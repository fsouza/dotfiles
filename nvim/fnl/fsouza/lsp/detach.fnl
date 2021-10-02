(import-macros {: if-nil} :fsouza-macros)

(local callbacks {})

(fn register [bufnr cb]
  (let [buf-cbs (if-nil (. callbacks bufnr) [])]
    (table.insert buf-cbs cb)
    (tset callbacks bufnr buf-cbs)))

(fn detach [bufnr]
  (let [buf-cbs (if-nil (. callbacks bufnr) [])]
    (each [_ cb (ipairs buf-cbs)]
      (cb bufnr)))
  (tset callbacks bufnr nil))

(macro get-lsp-client-ids []
  `(let [all-clients# (vim.lsp.get_active_clients)]
    (icollect [_# client# (ipairs all-clients#)]
      client.id)))

(fn restart []
  (let [original-client-ids (get-lsp-client-ids)
        check-new-clients (fn []
                            (let [current-client-ids (get-lsp-client-ids)]
                              (each [_ client-id (ipairs current-client-ids)]
                                (when (not (vim.tbl_contains original-client-ids client-id))
                                  (lua "return true, #current_client_ids")))

                              (values false (length current-client-ids))))
        timer (vim.loop.new_timer)]

    (vim.lsp.stop_client original-client-ids)
    (timer:start 50 50 (vim.schedule_wrap
                         (fn []
                           (let [(has-new-clients total-clients) (check-new-clients)]
                             (if has-new-clients
                               (timer:stop)
                               (when (= total-clients 0)
                                 (timer:stop)
                                 (vim.cmd "silent! edit")))))))))


{:register register
 :restart restart}
