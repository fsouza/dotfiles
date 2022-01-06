(let [fts {:extension {:tilt "bzl"
                       :fs "fsharp"
                       :fsx "fsharp"
                       :fsi "fsharp"
                       :fsproj "fsharp_project"}
           :filename {:Tiltfile "bzl"
                      :go.mod "gomod"}}]
  (vim.filetype.add fts))
