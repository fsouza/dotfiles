(local pl-path (require :pl.path))

(fn isrel [path start]
  (not (vim.startswith (pl-path.relpath path start) "../")))

(fn mkdir [path recursive cb]
  (let [cmd (if recursive
                [:mkdir :-p path]
                [:mkdir path])]
    (fn handle-result [result]
      (if (= result.code 1)
          (error result.stderr)
          (cb path)))

    (vim.system cmd nil (vim.schedule_wrap handle-result))))

(let [mod {: isrel : mkdir}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-path key)]
                                  (rawset table key value)
                                  value))}))
