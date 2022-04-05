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

(macro default-ruler []
  `(let [[lnum# col#] (vim.api.nvim_win_get_cursor 0)
         col# (+ (vim.str_utfindex (vim.api.nvim_get_current_line) col#) 1)]
     (string.format "%s   %d,%d   %s"
                    (mod-invoke :fsouza.lsp.diagnostics :ruler) lnum# col#
                    (line-percentage))))

(macro trim [msg width]
  `(let [chars# (- ,width 6)]
     (.. (string.sub ,msg 1 chars#) "...")))

(let [default-ruler-width 17
      max-ruler-width (math.floor (/ vim.o.columns 2))
      default-rulerformat (make-rulerformat default-ruler-width)]
  (fn adjust-ruler [msg]
    (let [width (length msg)
          msg (if (> width max-ruler-width) (trim msg max-ruler-width) msg)
          width (if (> width max-ruler-width) max-ruler-width width)]
      (update-rulerformat width)
      msg))

  (fn ruler []
    (let [notif (require :fsouza.lib.notif)]
      (if (notif.has-notification)
          (adjust-ruler (notif.get-notification))
          (do
            (tset vim.o :rulerformat default-rulerformat)
            (default-ruler)))))

  {: ruler : default-rulerformat})
