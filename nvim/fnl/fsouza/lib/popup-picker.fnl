(import-macros {: vim-schedule} :fsouza)

(fn min [x y]
  (if (< x y)
    x
    y))

(fn max [x y]
  (if (> x y)
    x
    y))

(fn close-others [win-var-identifier cb]
  (each [_ winid (ipairs (vim.api.nvim_list_wins))]
    (when (pcall vim.api.nvim_win_get_var winid win-var-identifier)
      (vim.api.nvim_win_close winid true)))
  (cb))

(fn handle-selection [mod winid]
  (let [index (. (vim.api.nvim_win_get_cursor 0) 1)
        {:cbs cbs} mod
        cb (. cbs winid)]
    (vim-schedule
      (vim.cmd "wincmd p")
      (mod.close winid)
      (cb index))))

(fn open [mod lines cb]
  (let [longest (* 2 (accumulate [longest 0 _ line (ipairs lines)]
                       (max longest (length line))))
        min-width 50
        max-width (* 3 min-width)
        bufnr (vim.api.nvim_create_buf false true)
        win-var-identifier "fsouza__popup-picker"
        win-opts {:relative "cursor"
                  :width (min (max longest min-width) max-width)
                  :height (length lines)
                  :col 0
                  :row 1
                  :style "minimal"}]

    (vim.api.nvim_buf_set_lines bufnr 0 -1 true lines)
    (close-others win-var-identifier (fn []
                                       (tset mod :cbs [])))

    (let [winid (vim.api.nvim_open_win bufnr true win-opts)
          {:cbs cbs} mod
          color (require "fsouza.color")
          helpers (require "fsouza.lib.nvim-helpers")]
      (tset cbs winid cb)
      (tset vim.bo :readonly true)
      (tset vim.bo :modifiable false)
      (tset vim.wo :cursorline true)
      (tset vim.wo :cursorlineopt "both")
      (tset vim.wo :number true)
      (tset vim.wo :wrap false)
      (vim.api.nvim_win_set_var winid win-var-identifier true)
      (color.set-popup-winid winid)

      (helpers.create-mappings {:n [{:lhs "<esc>"
                                     :rhs (helpers.fn-map (fn []
                                                            (let [popup-picker (require "fsouza.lib.popup-picker")]
                                                              (popup-picker.close winid))))}
                                    {:lhs "<cr>"
                                     :rhs (helpers.fn-map (fn []
                                                            (let [popup-picker (require "fsouza.lib.popup-picker")]
                                                              (popup-picker.handle-selection winid))))}
                                    {:lhs "<c-n>"
                                     :rhs "<down>"
                                     :opts {:noremap true}}
                                    {:lhs "<c-p>"
                                     :rhs "<up>"
                                     :opts {:noremap true}}]} bufnr))))


(let [cbs {}
      mod {:handle-selection (fn [winid]
                               (handle-selection mod winid))
           :close (fn [winid]
                    (tset cbs winid nil)
                    (vim.api.nvim_win_close winid false))
           :open (fn [lines cb]
                   (open mod lines cb))}]
  mod)
