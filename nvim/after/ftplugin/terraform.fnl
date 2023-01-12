(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :terraform-ls
                      :cmd [:go
                            :run
                            "github.com/hashicorp/terraform-ls@main"
                            :serve]}})
