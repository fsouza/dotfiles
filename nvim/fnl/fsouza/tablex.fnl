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

(fn exists [pl-tablex t pred]
  (not (= (pl-tablex.find_if t pred) nil)))

(let [pl-tablex (require "pl.tablex")
      tablex {:flat_map flat-map
              :filter_map filter-map
              :flatten vim.tbl_flatten
              :exists (partial exists pl-tablex)}]
  (setmetatable tablex { "__index" (fn [table key]
                                     (let [value (. pl-tablex key)]
                                       (rawset table key value)
                                       value)) }))
