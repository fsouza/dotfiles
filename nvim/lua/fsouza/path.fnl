(local pl-path (require :pl.path))
(fn isrel [path start]
  (not (vim.startswith (pl-path.relpath path start) "../")))

(let [pl-path (require :pl.path)
      mod {: isrel}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-path key)]
                                  (rawset table key value)
                                  value))}))
