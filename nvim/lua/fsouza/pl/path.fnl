(import-macros {: mod-invoke} :helpers)

(local pl-path (require :pl.path))

(fn isrel [path start]
  (not (vim.startswith (pl-path.relpath path start) "../")))

(fn async-mkdir [path mode recursive cb]
  (vim.loop.fs_mkdir path mode
                     #(let [err (mod-invoke :fsouza.lib.nvim-helpers
                                            :extract-luv-error $1)]
                        (if (= err nil)
                            (cb)
                            (match err
                              :EACCES (cb $1)
                              :EEXIST (if recursive
                                          (cb)
                                          (cb $1))
                              :ENOENT (if recursive
                                          (let [parent (pl-path.dirname path)]
                                            (async-mkdir parent mode recursive
                                                         #(if $1
                                                              (cb $1)
                                                              (async-mkdir path
                                                                           mode
                                                                           false
                                                                           cb))))
                                          (cb $1))
                              _ (cb $1))))))

(let [mod {: isrel : async-mkdir}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-path key)]
                                  (rawset table key value)
                                  value))}))
