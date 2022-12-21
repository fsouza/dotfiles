(import-macros {: if-nil : mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(fn start-efm [bufnr cb]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               : cb
               :config {:name :efm
                        :cmd [(get-cache-cmd :efm-langserver)]
                        :init_options {:documentFormatting true}
                        :settings {:lintDebounce :250ms
                                   :rootMarkers [:.git]
                                   :languages {}}}}))

(fn should-add [current-tools tool]
  (if (or tool.formatCommand tool.lintCommand)
      (let [seq (require :fsouza.pl.seq)
            s (-> current-tools
                  (seq.list)
                  (seq.filter #(and (= $1.formatCommand tool.formatCommad)
                                    (= $1.lintCommand tool.lintCommand)))
                  (seq.take 1))]
        (= (s) nil))
      false))

(lambda add [bufnr language tools]
  (fn update-config [client-id]
    (let [client (vim.lsp.get_client_by_id client-id)]
      (when client
        (var changed false)
        (let [settings client.config.settings
              current-tools (if-nil (?. settings :languages language) [])]
          (each [_ tool (ipairs tools)]
            (when (should-add current-tools tool)
              (set changed true)
              (table.insert current-tools tool)))
          (when changed
            (tset settings.languages language current-tools)
            (tset client.config :settings settings)
            (client.notify :workspace/didChangeConfiguration {: settings}))))))

  (start-efm bufnr update-config))

{: add}
