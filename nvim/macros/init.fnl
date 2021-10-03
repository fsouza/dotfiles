(let [fennel (require :fennel)
      macro-path (.. fennel.macro-path ";macros/?.fnl")]
  (tset fennel :macro-path macro-path))
