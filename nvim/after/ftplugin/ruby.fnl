(import-macros {: mod-invoke} :helpers)

(fn is-rspec-file [fname]
  (not= (string.find fname "spec/.*_spec%.rb$") nil))

(fn start-sorbet [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               :config {:name :sorbet :cmd [:bundle :exec :srb :tc :--lsp]}}))

(fn start-solargraph [bufnr]
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               :config {:name :solargraph :cmd [:solargraph :stdio]}
               :cb #(mod-invoke :fsouza.lsp.references :register-test-checker
                                :.rb is-rspec-file)}))

(fn start-efm [bufnr]
  (let [rubocop {:lintCommand "bundle exec rubocop --format emacs --stdin ${INPUT}"
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
  (vim.uv.fs_stat :sorbet
                  #(when (not $1)
                     (vim.schedule #(start-sorbet bufnr)))))
