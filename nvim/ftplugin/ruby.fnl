(import-macros {: mod-invoke} :helpers)

(fn start-sorbet [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               :config {:name :sorbet :cmd [:bundle :exec :srb :tc :--lsp]}}))

(fn start-solargraph [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr :config {:name :solargraph :cmd [:solargraph :stdio]}}))

(fn start-efm [bufnr]
  (let [rubocop {:lintCommand "bundle exec rubocop --stdin ${INPUT}"
                 :lintStdin true
                 :lintSource :rubocop
                 :lintFormats ["%f:%l:%c: %m"]
                 :lintIgnoreExitCode true
                 :rootMarkers [:.rubocop.yml]
                 :requireMarker true}]
    (mod-invoke :fsouza.lsp.servers.efm :add bufnr :ruby [rubocop])))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (start-solargraph bufnr)
  (start-efm bufnr)
  (vim.loop.fs_stat :sorbet
                    #(when (not $1)
                       (vim.schedule #(start-sorbet bufnr)))))
