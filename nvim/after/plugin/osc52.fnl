(import-macros {: mod-invoke} :helpers)

(let [get-osc52 (mod-invoke :fsouza.lib.nvim-helpers :once
                            #(let [osc52 (require :osc52)]
                               (osc52.setup {:silent true})
                               osc52))]
  (lambda copy [lines]
    (let [osc52 (get-osc52)]
      (-> lines
          (table.concat "\n")
          (osc52.copy))))
  (lambda paste []
    [(-> ""
         (vim.fn.getreg)
         (vim.fn.split "\n"))
     (vim.fn.getregtype "")])
  (when vim.env.SSH_CLIENT
    (tset vim.g :clipboard
          {:name :osc52 :copy {:+ copy :* copy} :paste {:+ paste :* paste}})))
