(import-macros {: reload} :helpers)

(let [factory (reload :fsouza.themes.none-factory)]
  (factory {:darker-gray :#333333
            :dark-gray :#5f5f5f
            :gray :#9e8171
            :light-gray :#aea191
            :lighter-gray :#ded1c1
            :black :#262626
            :red :#990000
            :brown :#5f0000
            :white :#fef1e1
            :pink :#ffd7ff
            :orange :#ffd787
            :blue :#000066}))
