(import-macros {: if-nil : mod-invoke} :helpers)

(fn rename []
  (let [bufnr (vim.api.nvim_get_current_buf)
        client (mod-invoke :fsouza.lsp.clients :get-client bufnr
                           :renameProvider)]
    (fn rename [placeholder]
      (let [placeholder (if-nil placeholder (vim.fn.expand :<cword>))
            new-name (vim.fn.input "New name: " placeholder)
            params (vim.lsp.util.make_position_params)]
        (when (and new-name (not= new-name ""))
          (tset params :newName new-name)
          (client.request :textDocument/rename params))))

    (fn prepare-rename-cb [_ result]
      (if (?. result :placeholder)
          (rename result.placeholder)
          (and (?. result :start :line) (?. result :end :line)
               (= result.start.line result.end.line))
          (let [[line] (vim.api.nvim_buf_get_lines bufnr result.start.line
                                                   (+ result.start.line 1) true)
                pos-first-char (+ result.start.character 1)
                pos-last-char (+ result.end.character)
                placeholder (string.sub line pos-first-char pos-last-char)]
            (rename placeholder))
          (vim.notify "can't rename current position")))

    (when client
      (let [provider client.server_capabilities.renameProvider
            supports-prepare (if (= (type provider) :table)
                                 provider.prepareProvider
                                 false)]
        (if supports-prepare
            (client.request :textDocument/prepareRename
                            (vim.lsp.util.make_position_params)
                            prepare-rename-cb bufnr)
            (rename))))))

{: rename}
