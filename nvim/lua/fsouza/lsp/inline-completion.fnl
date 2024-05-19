(local ns-name :fsouza__inlineCompletion)
(local extmark-id 1)
(local hl-group :InlineCompletion)

(fn ensure-ns [name]
  (let [ns-id (-> (vim.api.nvim_get_namespaces)
                  (vim.iter)
                  (: :filter #(= $1 name))
                  (: :next))]
    (or ns-id (vim.api.nvim_create_namespace name))))

(fn detach [bufnr client-id])

(fn complete [bufnr client-id]
  (let [client (vim.lsp.get_client_by_id client-id)]
    (if (not client)
        (detach bufnr client-id)
        (let [ns-id (ensure-ns ns-name)
              params (vim.lsp.make_position_params)]
          (tset params :context {:triggerKind 2})
          (client.request :textDocument/inlineCompletion params
                          #(if (not= $1 nil)
                               (error $1)
                               (let [result $2
                                     item (?. result :items 1)]
                                 (vim.api.nvim_buf_del_extmark bufnr ns-id
                                                               extmark-id)
                                 (when item
                                   (let [text (vim.split item.insertText "\n")
                                         opts {:id extmark-id
                                               :virt_text [[(. text 1)
                                                            hl-group]]
                                               :virt_text_pos :overlay
                                               :hl_mode :combine}]
                                     (when (> (length text) 1)
                                       (tset opts :virt_lines
                                             (-> text
                                                 (vim.iter)
                                                 (: :skip 1)
                                                 (: :map #[$1 hl-group])
                                                 (: :totable))))
                                     (vim.api.nvim_buf_set_extmark bufnr ns-id
                                                                   item.range.start.line
                                                                   item.range.start.character
                                                                   opts))))))))))

(fn attach [bufnr client-id])
