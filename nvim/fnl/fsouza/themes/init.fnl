(setmetatable {} {"__index" (fn [table key]
                              (let [theme-factory (require (.. "fsouza.themes." key))
                                    theme (theme-factory)]
                                (rawset table key theme)
                                theme))})
