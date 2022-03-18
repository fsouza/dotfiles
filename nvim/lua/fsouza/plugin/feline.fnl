(import-macros {: if-nil} :helpers)

(fn get-mode-text []
  (let [echo-modes {:Rc :REPLACE
                    :R :REPLACE
                    :Rv :REPLACE
                    :Rx :REPLACE
                    :i :INSERT
                    :v :VISUAL
                    :V "VISUAL LINE"
                    "" "VISUAL BLOCK"
                    :t :TERMINAL}
        {: mode} (vim.api.nvim_get_mode)
        output (. echo-modes mode)]
    (if output (string.format "%s | " output) "")))

(fn get-cwd []
  (let [path (require :pl.path)]
    (path.basename (vim.loop.cwd))))

(let [gps (require :nvim-gps)
      bg "#d0d0d0"
      fg "#262626"
      red "#990000"
      orange "#ffd787"
      theme {: bg : fg :black fg}
      cwd-provider {:provider {:name :get-cwd :update [:DirChanged]}
                    :right_sep [" " {:str ">" :hl {: fg : bg}} " "]}
      components {:active [[{:provider {:name :get-mode-text
                                        :update [:ModeChanged]}}
                            cwd-provider
                            {:provider {:name :file_info
                                        :opts {:type :relative}}
                             :icon ""}
                            {:provider gps.get_location
                             :enabled gps.is_available
                             :left_sep [" " {:str ">" :hl {: fg : bg}} " "]}]
                           [{:provider :diagnostic_errors
                             :hl {:fg red}
                             :icon " E-"}
                            {:provider :diagnostic_warnings
                             :hl {:fg orange}
                             :icon " W-"}
                            {:provider :diagnostic_hints
                             :hl {: fg}
                             :icon " H-"}
                            {:provider :diagnostic_info :hl {: fg} :icon " I-"}
                            {:provider {:name :position :opts {:padding true}}
                             :left_sep "    "
                             :icon ""}
                            {:provider :line_percentage
                             :left_sep "   "
                             :right_sep " "
                             :icon ""}]]
                  :inactive [[cwd-provider {:provider :file_type :icon ""}]]}
      feline (require :feline)]
  (feline.setup {: theme
                 : components
                 :default_bg bg
                 :default_fg fg
                 :custom_providers {: get-cwd : get-mode-text}}))
