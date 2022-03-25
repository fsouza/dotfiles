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
  (let [path (require :pl.path)
        cwd (vim.loop.cwd)
        home (vim.loop.os_homedir)]
    (if (= cwd home) "~" (path.basename cwd))))

(fn get-file-type []
  (let [mapping {:fsouza-terminal :terminal}
        ft (vim.api.nvim_buf_get_option 0 :filetype)
        ft (if-nil (. mapping ft) ft)]
    (string.format "[%s]" ft)))

(let [gps (require :nvim-gps)
      notif (require :fsouza.lib.notif)
      bg "#d0d0d0"
      fg "#262626"
      error "#990000"
      warning "#a36d00"
      theme {: bg : fg :black fg : error : warning}
      cwd-provider {:provider {:name :get-cwd :update [:DirChanged]}
                    :right_sep [" " {:str ">" :hl {:fg :fg :bg :bg}} " "]}
      components {:active [[{:provider {:name :get-mode-text
                                        :update [:ModeChanged]}}
                            cwd-provider
                            {:provider {:name :file_info
                                        :opts {:type :relative}}
                             :icon ""}
                            {:provider gps.get_location
                             :enabled gps.is_available
                             :left_sep [" "
                                        {:str ">" :hl {:fg :fg :bg :bg}}
                                        " "]}]
                           [{:provider notif.get-notification
                             :enabled notif.has-notification}
                            {:provider :diagnostic_errors
                             :hl {:fg :error}
                             :icon " E-"
                             :left_sep "  "}
                            {:provider :diagnostic_warnings
                             :hl {:fg :warning}
                             :icon " W-"}
                            {:provider :diagnostic_hints
                             :hl {:fg :fg}
                             :icon " H-"}
                            {:provider :diagnostic_info
                             :hl {:fg :fg}
                             :icon " I-"
                             :right_sep "  "}
                            {:provider {:name :position :opts {:padding true}}
                             :left_sep "  "
                             :right_sep "  "
                             :icon ""}
                            {:provider :line_percentage
                             :right_sep " "
                             :icon ""}]]
                  :inactive [[{:provider :get-file-type :icon ""}]]}
      feline (require :feline)]
  (feline.setup {: theme
                 : components
                 :default_bg bg
                 :default_fg fg
                 :custom_providers {: get-cwd : get-mode-text : get-file-type}})
  (feline.add_theme :none theme))
