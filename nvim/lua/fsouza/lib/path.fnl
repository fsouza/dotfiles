(import-macros {: mod-invoke} :helpers)

(local pl-path (require :pl.path))

(fn isrel [path start]
  (not (vim.startswith (pl-path.relpath path start) "../")))

(fn mkdir [path mode recursive cb]
  (let [args (if recursive
                 [:-p path]
                 [path])]
    (fn handle-result [result]
      (if (= result.exit-status 1)
          (error result.stderr)
          (cb path)))

    (mod-invoke :fsouza.lib.cmd :mkdir {: args} handle-result)))

(let [mod {: isrel : mkdir}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-path key)]
                                  (rawset table key value)
                                  value))}))
