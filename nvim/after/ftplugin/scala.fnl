(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start {:config {:name :metals :cmd [:metals]}})
