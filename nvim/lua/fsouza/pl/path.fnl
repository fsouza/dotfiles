(import-macros {: mod-invoke} :helpers)

(local pl-path (require :pl.path))

(fn isrel [path start]
  (not (vim.startswith (pl-path.relpath path start) "../")))

(fn async-mkdir [path mode recursive cb]
  (vim.uv.fs_mkdir path mode #(let [err (mod-invoke :fsouza.lib.nvim-helpers
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
                                                    (async-mkdir parent mode
                                                                 recursive
                                                                 #(if $1
                                                                      (cb $1)
                                                                      (async-mkdir path
                                                                                   mode
                                                                                   false
                                                                                   cb))))
                                                  (cb $1))
                                      _ (cb $1))))))

(fn async-write-file [path mode content cb]
  (vim.uv.fs_open path :w mode
                  #(when (= $1 nil)
                     (let [fd $2]
                       (vim.uv.fs_write fd content nil
                                        #(do
                                           (vim.uv.fs_close fd)
                                           (when (= $1 nil)
                                             (cb))))))))

(fn path-entries [path]
  (let [path (or path (vim.uv.os_getenv :PATH))]
    (vim.split path ":" {:trimempty true :plain true})))

(fn async-which [exec cb path]
  (fn handle-p [p cb]
    (vim.uv.fs_stat p #(if $1
                           (cb "")
                           (let [mode (. $2 :mode)
                                 S_IXUSR (mod-invoke :lua_system_constants
                                                     :S_IXUSR)]
                             (if (band mode S_IXUSR)
                                 (cb p)
                                 (cb ""))))))

  (if (pl-path.isabs exec)
      (handle-p exec cb)
      (let [dirs (path-entries path)]
        (fn try-dir [idx]
          (if (> idx (length dirs))
              (cb "")
              (let [dir (. dirs idx)
                    candidate (pl-path.join dir exec)]
                (handle-p candidate
                          #(if (= $1 "")
                               (try-dir (+ idx 1))
                               (cb $1))))))

        (try-dir 1))))

(let [mod {: isrel : async-mkdir : async-which : async-write-file}]
  (setmetatable mod {:__index (fn [table key]
                                (let [value (. pl-path key)]
                                  (rawset table key value)
                                  value))}))
