(macro tabstop []
  8)

(lambda indent-style [bufnr val opts]
  (tset (. vim :bo bufnr) :expandtab (= val :space)))

(lambda indent-size [bufnr val opts]
  (let [indent-size (if (= val :tab) (tabstop)
                        (. opts.indent_style :space) (tonumber val)
                        0)]
    (tset (. vim :bo bufnr) :shiftwidth indent-size)
    (tset (. vim :bo bufnr) :softtabstop indent-size)
    (tset (. vim :bo bufnr) :tabstop (tabstop))))

(lambda tab-width [bufnr val opts]
  (tset (. vim :bo bufnr) :tabstop (tabstop)))

(let [editorconfig (require :editorconfig)]
  (tset editorconfig.properties :indent_style indent-style)
  (tset editorconfig.properties :indent_size indent-size)
  (tset editorconfig.properties :tab_width tab-width))
