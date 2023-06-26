(import-macros {: mod-invoke} :helpers)

(fn rename [client bufnr]
  (fn rename [placeholder]
    (let [placeholder (or placeholder (vim.fn.expand :<cword>))
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
        (vim.api.nvim_echo [["can't rename at current position" :WarningMsg]]
                           true {})))

  (let [method :textDocument/prepareRename]
    (if (client.supports_method method)
        (client.request method (vim.lsp.util.make_position_params)
                        prepare-rename-cb bufnr)
        (rename))))

{: rename}
