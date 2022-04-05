(import-macros {: mod-invoke : vim-schedule} :helpers)

(macro ruler-suffix []
  "(%=%{v:lua.require('fsouza.plugin.ruler').ruler()}%)")

(macro make-rulerformat [width]
  `(.. "%" ,width (ruler-suffix)))

(macro line-percentage []
  `(let [[lnum# _#] (vim.api.nvim_win_get_cursor 0)
         lines# (vim.api.nvim_buf_line_count 0)]
     (if (= lnum# 1) :Top
         (= lnum# lines#) :Bot
         (string.format "%2d%%" (math.ceil (* (/ lnum# lines#) 99))))))

(macro update-rulerformat [width]
  `(vim-schedule (tset vim.o :rulerformat (make-rulerformat ,width))))

(macro render-ruler [msg]
  `(let [[lnum# col#] (vim.api.nvim_win_get_cursor 0)
         col# (+ (vim.str_utfindex (vim.api.nvim_get_current_line) col#) 1)]
     (string.format "%s   %s   %d,%d   %s" ,msg
                    (mod-invoke :fsouza.lsp.diagnostics :ruler) lnum# col#
                    (line-percentage))))

(macro trim [msg width]
  `(let [chars# (- ,width 9)]
     (.. (string.sub ,msg 1 chars#) "...")))

(let [default-ruler-width 19
      max-ruler-width 100
      max-msg-width (- max-ruler-width default-ruler-width)
      default-rulerformat (make-rulerformat default-ruler-width)]
  (fn extend-ruler [msg]
    (let [width (length msg)
          msg (if (> width max-msg-width) (trim msg max-msg-width) msg)
          width (length msg)]
      (update-rulerformat (+ default-ruler-width width 5))))

  (fn ruler []
    (let [notif (require :fsouza.lib.notif)]
      (let [msg (if (notif.has-notification) (notif.get-notification) "")]
        (extend-ruler msg)
        (render-ruler msg))))

  {: ruler : default-rulerformat})
