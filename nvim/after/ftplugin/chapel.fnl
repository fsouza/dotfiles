(import-macros {: mod-invoke} :helpers)

(fn start-chpl-lsps [bufnr chpl-home chpl-bin-subdir]
  (let [path (require :fsouza.pl/path)
        chplcheck (path.join chpl-home :bin chpl-bin-subdir :chplcheck)
        chpl-language-server (path.join chpl-home :bin chpl-bin-subdir
                                        :chpl-language-server)]
    (mod-invoke :fsouza.lsp.servers :start
                {:config {:name :chplcheck :cmd [chplcheck :--lsp]}})
    (mod-invoke :fsouza.lsp.servers :start
                {:config {:name :chpl-language-server
                          :cmd [chpl-language-server :--resolver]}})))

(when vim.env.CHPL_HOME
  (let [bufnr (vim.api.nvim_get_current_buf)
        path (require :fsouza.pl.path)
        chpl-bin-subdir (path.join vim.env.CHPL_HOME :util :chplenv
                                   :chpl_bin_subdir.py)]
    (mod-invoke :fsouza.lib.cmd :run :python3 {:args [chpl-bin-subdir]}
                #(when (= $1.exit-status 0)
                   (->> $1.stdout
                        (vim.trim)
                        (start-chpl-lsps bufnr vim.env.CHPL_HOME))))))
