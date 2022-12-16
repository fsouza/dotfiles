(import-macros {: if-nil} :helpers)

(local callbacks {})

(fn register [bufnr cb]
  (let [buf-cbs (if-nil (. callbacks bufnr) [])]
    (table.insert buf-cbs cb)
    (tset callbacks bufnr buf-cbs)))

(fn detach [bufnr]
  (let [buf-cbs (if-nil (. callbacks bufnr) [])]
    (each [_ cb (ipairs buf-cbs)]
      (pcall cb bufnr)))
  (tset callbacks bufnr nil))

(macro get-lsp-client-ids []
  `(let [all-clients# (vim.lsp.get_active_clients)]
     (icollect [_# client# (ipairs all-clients#)]
       client#.id)))

(fn detach-all-buffers []
  (let [bufnrs (vim.api.nvim_list_bufs)]
    (each [_ bufnr (ipairs bufnrs)]
      (detach bufnr))))

(fn restart []
  (let [seq (require :pl.seq)
        original-client-ids (get-lsp-client-ids)
        timer (vim.loop.new_timer)]
    (fn check-new-clients []
      (let [current-client-ids (get-lsp-client-ids)
            s (-> current-client-ids
                  (seq.list)
                  (seq.filter #(not (vim.tbl_contains original-client-ids $1))))
            has-new-clients (if (s) true false)]
        (values has-new-clients (length current-client-ids))))

    (vim.lsp.stop_client original-client-ids)
    (detach-all-buffers)
    (timer:start 50 50
                 (vim.schedule_wrap #(let [(has-new-clients total-clients) (check-new-clients)]
                                       (if has-new-clients
                                           (timer:stop)
                                           (when (= total-clients 0)
                                             (timer:stop)
                                             (vim.cmd.doautoall :FileType))))))))

{: register : restart}
