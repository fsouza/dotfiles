(import-macros {: mod-invoke} :helpers)

(let [mod-dir (mod-invoke :fsouza.pl.path :join _G.dotfiles-dir :nvim
                          :langservers)]
  (tset vim.bo :commentstring "#%s")
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :terraform-ls
                        :cmd [:go
                              :run
                              :-C
                              mod-dir
                              :github.com/hashicorp/terraform-ls
                              :serve]}
               :opts {:autofmt true}}))
