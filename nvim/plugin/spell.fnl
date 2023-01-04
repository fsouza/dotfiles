(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__auto_spell
            [{:events [:FileType]
              :targets [:changelog :gitcommit :help :markdown :text]
              :command "setlocal spell"}])
