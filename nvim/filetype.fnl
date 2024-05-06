(fn from-shebang [path bufnr]
  (let [pattern-mapping {:python :python
                         :bash :bash
                         :zsh :zsh
                         :/sh :sh
                         :ruby :ruby
                         "env sh" :sh}
        [first-line] (vim.api.nvim_buf_get_lines bufnr 0 1 true)
        (_ _ prog) (string.find first-line "^#!(.+)")]
    (when prog
      (let [k (-> pattern-mapping
                  (pairs)
                  (vim.iter)
                  (: :filter #(if (string.find prog $1) true false))
                  (: :next))]
        (when k
          (. pattern-mapping k))))))

(fn from-current-shell []
  (let [shell (os.getenv :SHELL)]
    (when shell
      (vim.fs.basename shell))))

(let [fts {:extension {:fnl :fennel
                       :sh #(or (from-shebang $...) (from-current-shell))
                       :chpl :chapel
                       "" from-shebang}
           :filename {:go.mod :gomod :setup.cfg :pysetupcfg :Brewfile :ruby}}]
  (vim.filetype.add fts))
