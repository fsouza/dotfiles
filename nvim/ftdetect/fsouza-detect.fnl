(let [helpers (require "fsouza.lib.nvim-helpers")
      mappings [{:ft "bzl" :patterns ["Tiltfile" "*.tilt"]}
                {:ft "fsharp" :patterns ["*.fs" "*.fsx" "*.fsi"]}
                {:ft "fsharp_project" :patterns ["*.fsproj"]}
                {:ft "gomod" :patterns ["go.mod"]}]]
  (helpers.augroup
    "fsouza__ftdetect"
    (icollect [_ m (ipairs mappings)]
      {:events ["BufNewFile" "BufRead"]
       :targets m.patterns
       :command (helpers.fn-cmd (fn []
                                  (tset vim.o :filetype m.ft)))})))
