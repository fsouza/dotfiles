(import-macros {: mod-invoke} :helpers)

(local pl-seq (require :pl.seq))

(fn map [iter f arg]
  (pl-seq.map f iter arg))

(let [mod {: map}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-seq key)]
                                  (rawset table key value)
                                  value))}))
