(import-macros {: mod-invoke : if-nil} :helpers)

(fn filter [prefix entry]
  (if (= prefix "") 999 (let [score (mod-invoke :fzy :score prefix entry)]
                          (if (< score 0) 0 score))))

{: filter}
