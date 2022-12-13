(import-macros {: mod-invoke} :helpers)

(fn start-sorbet []
  (mod-invoke :fsouza.lsp.servers :start
              {:name :sorbet :cmd [:bundle :exec :srb :tc :--lsp]}))

(fn start-solargraph []
  (mod-invoke :fsouza.lsp.servers :start
              {:name :solargraph :cmd [:solargraph :stdio]}))

(vim.loop.fs_stat :sorbet #(if $1
                               (start-solargraph)
                               (start-sorbet)))
