(import-macros {: mod-invoke : vim-schedule} :helpers)

(fn start-sorbet [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               :config {:name :sorbet :cmd [:bundle :exec :srb :tc :--lsp]}}))

(fn start-solargraph [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr :config {:name :solargraph :cmd [:solargraph :stdio]}}))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (start-solargraph bufnr)
  (vim.loop.fs_stat :sorbet
                    #(when (not $1)
                       (vim-schedule (start-sorbet bufnr)))))
