(import-macros {: mod-invoke} :helpers)

(let [mod-dir (vim.fs.joinpath _G.dotfiles-dir :nvim :langservers)]
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
