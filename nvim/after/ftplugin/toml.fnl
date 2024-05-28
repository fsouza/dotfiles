(let [servers (require :fsouza.lsp.servers)]
  (servers.start {:config {:name :taplo :cmd [:taplo :lsp :stdio]}
                  :opts {:autofmt true}}))
