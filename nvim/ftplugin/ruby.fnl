(import-macros {: mod-invoke : vim-schedule} :helpers)

(fn start-sorbet []
  (mod-invoke :fsouza.lsp.servers :start
              {:name :sorbet :cmd [:bundle :exec :srb :tc :--lsp]}))

(fn start-solargraph []
  (mod-invoke :fsouza.lsp.servers :start
              {:name :solargraph :cmd [:solargraph :stdio]}))

(start-solargraph)
(vim.loop.fs_stat :sorbet
                  #(when (not $1)
                     (vim-schedule (start-sorbet))))
