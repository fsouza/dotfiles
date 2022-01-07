(fn from-shebang [path bufnr]
  (let [pattern-mapping {:python "python"
                         :bash "sh"
                         :zsh "sh"
                         :/sh "sh"
                         "env sh" "sh"}
        lines (vim.api.nvim_buf_get_lines bufnr 0 1 true)
        first-line (. lines 1)
        (_ _ prog) (string.find first-line "^#!(.+)")]
    (when prog
      (each [pattern ft (pairs pattern-mapping)]
        (when (string.find prog pattern)
          (lua "return ft"))))))

(let [fts {:extension {:tilt "bzl"
                       :fs "fsharp"
                       :fsx "fsharp"
                       :fsi "fsharp"
                       :fsproj "fsharp_project"
                       "" from-shebang}
           :filename {:Tiltfile "bzl"
                      :go.mod "gomod"}}]
  (vim.filetype.add fts))
