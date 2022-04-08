(import-macros {: mod-invoke} :helpers)

(macro max-score []
  999)

(macro min-score []
  0)

(local infinity-n (/ 1 0))

(macro eq [left right]
  `(let [left# (string.lower ,left)
         right# (string.lower ,right)]
     (= left# right#)))

(fn filter [prefix entry]
  (if (= prefix "")
      (max-score)
      (let [score (mod-invoke :fzy :score prefix entry)]
        (if (< score 0)
            (min-score)
            (if (< score infinity-n)
                score
                (if (eq prefix entry)
                    (max-score)
                    (min-score)))))))

{: filter}
