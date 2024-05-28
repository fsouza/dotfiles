(fn start-efm [bufnr cb]
  (let [mod-dir (vim.fs.joinpath _G.dotfiles-dir :nvim :langservers)
        servers (require :fsouza.lsp.servers)]
    (servers.start {: bufnr
                    : cb
                    :opts {:autofmt 1}
                    :config {:name :efm
                             :cmd [:go
                                   :run
                                   :-C
                                   mod-dir
                                   :github.com/mattn/efm-langserver]
                             :init_options {:documentFormatting true}
                             :settings {:lintDebounce :250ms
                                        :rootMarkers [:.git]
                                        :languages {}}}})))

(fn should-add [current-tools tool]
  (let [iter (vim.iter current-tools)]
    (not (iter:any #(or (and (not= tool.formatCommand nil)
                             (= $1.formatCommand tool.formatCommand))
                        (and (not= tool.lintCommand nil)
                             (= $1.lintCommand tool.lintCommand)))))))

(lambda add [bufnr language tools]
  (fn update-config [client-id]
    (let [client (vim.lsp.get_client_by_id client-id)]
      (when client
        (var changed false)
        (let [settings client.config.settings
              current-tools (or (?. settings :languages language) [])]
          (each [_ tool (ipairs tools)]
            (when (should-add current-tools tool)
              (set changed true)
              (table.insert current-tools tool)))
          (when changed
            (tset settings.languages language current-tools)
            (tset client.config :settings settings)
            (client.notify :workspace/didChangeConfiguration {: settings}))))))

  (when (> (length tools) 0)
    (start-efm bufnr update-config)))

{: add}
