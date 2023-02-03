(import-macros {: mod-invoke} :helpers)

(lambda copy [lines]
  (let [osc52 (require :osc52)]
    (-> lines
        (table.concat "\n")
        (osc52.copy))))

(lambda paste []
  [(-> ""
       (vim.fn.getreg)
       (vim.fn.split "\n"))
   (vim.fn.getregtype "")])

(when vim.env.SSH_CLIENT
  (tset vim.g :clipboard {:name :osc52
                          :copy {:+ copy :* copy}
                          :paste {:+ paste :* paste}}))
