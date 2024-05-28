(import-macros {: mod-invoke} :helpers)

(do
  (tset vim.b (.. :surround_ (string.byte :l)) "[\r](\001url: \001)")
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :markdown-language-server
                        :cmd [:vscode-markdown-language-server :--stdio]}}))
