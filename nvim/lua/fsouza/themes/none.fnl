(import-macros {: reload} :helpers)

(let [factory (reload :fsouza.themes.none-factory)]
  (factory {:darker-gray "#333333"
            :dark-gray "#5f5f5f"
            :gray "#afafaf"
            :light-gray "#d0d0d0"
            :lighter-gray "#dadada"
            :black "#262626"
            :red "#990000"
            :brown "#5f0000"
            :white "#ececec"
            :pink "#ffd7ff"
            :orange "#ffd787"
            :blue "#000066"}))
