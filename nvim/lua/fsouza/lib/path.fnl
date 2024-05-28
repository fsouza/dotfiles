(local pl-path (require :pl.path))

(fn isrel [path start]
  (not (vim.startswith (pl-path.relpath path start) "../")))

(fn mkdir [path recursive cb]
  (let [args (if recursive
                 [:-p path]
                 [path])
        cmd (require :fsouza.lib.cmd)]
    (fn handle-result [result]
      (if (= result.exit-status 1)
          (error result.stderr)
          (cb path)))

    (cmd.run :mkdir {: args} handle-result)))

(let [mod {: isrel : mkdir}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-path key)]
                                  (rawset table key value)
                                  value))}))
