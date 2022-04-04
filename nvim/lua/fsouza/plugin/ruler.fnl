(import-macros {: mod-invoke} :helpers)

(macro line-percentage []
  `(let [[lnum# _#] (vim.api.nvim_win_get_cursor 0)
         lines# (vim.api.nvim_buf_line_count 0)]
     (if (= lnum# 1) :Top
         (= lnum# lines#) :Bot
         (string.format "%2d%%" (math.ceil (* (/ lnum# lines#) 99))))))

(macro default-ruler []
  `(let [[lnum# col#] (vim.api.nvim_win_get_cursor 0)]
     (string.format "%s   %d,%d   %s"
                    (mod-invoke :fsouza.lsp.diagnostics :ruler) lnum# col#
                    (line-percentage))))

(fn ruler []
  (let [notif (require :fsouza.lib.notif)]
    (if (notif.has-notification)
        (notif.get-notification)
        (default-ruler))))

{: ruler}
