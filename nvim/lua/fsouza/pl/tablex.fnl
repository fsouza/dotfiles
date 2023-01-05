(local pl-tablex (require :pl.tablex))

(fn flat-map [f t]
  (let [result []]
    (each [key value (pairs t)]
      (each [_ output (ipairs (f value key))]
        (table.insert result output)))
    result))

(fn filter-map [f t]
  (let [result []]
    (each [key value (pairs t)]
      (let [r (f value key)]
        (when r
          (table.insert result r))))
    result))

(fn exists [t pred]
  (not= (pl-tablex.find_if t pred) nil))

(fn for-all [t pred]
  (not (exists t #(not (pred $...)))))

(let [mod {: flat-map : filter-map :flatten vim.tbl_flatten : exists : for-all}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-tablex key)]
                                  (rawset table key value)
                                  value))}))
