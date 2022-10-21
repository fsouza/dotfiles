(fn from-shebang [path bufnr]
  (let [seq (require :pl.seq)
        pattern-mapping {:python :python
                         :bash :sh
                         :zsh :sh
                         :/sh :sh
                         :ruby :ruby
                         "env sh" :sh}
        [first-line] (vim.api.nvim_buf_get_lines bufnr 0 1 true)
        (_ _ prog) (string.find first-line "^#!(.+)")]
    (when prog
      (let [s (-> pattern-mapping
                  (seq.keys)
                  (seq.filter #(if (string.find prog $1) true false))
                  (seq.take 1))]
        (s)))))

(let [fts {:extension {:tilt :bzl
                       :fs :fsharp
                       :fsx :fsharp
                       :fsi :fsharp
                       :fnl :fennel
                       :thrift :thrift
                       :fsproj :fsharp_project
                       "" from-shebang}
           :filename {:Tiltfile :bzl
                      :go.mod :gomod
                      :setup.cfg :pysetupcfg
                      :Brewfile :ruby}}]
  (vim.filetype.add fts))
