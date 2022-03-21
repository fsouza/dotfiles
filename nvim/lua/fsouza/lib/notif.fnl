(let [nvim-helpers (require :fsouza.lib.nvim-helpers)]
  (var last-notification nil)
  (var timer nil)
  {:notify #(do
              (set last-notification $1)
              (when (not= timer nil)
                (timer:stop)
                (timer:close)
                (set timer nil)))
   :has-notification #(not= last-notification nil)
   :get-notification #(let [msg last-notification]
                        (if (= timer nil)
                            (do
                              (set timer (vim.loop.new_timer))
                              (timer:start 6000 0
                                           #(do
                                              (timer:stop)
                                              (timer:close)
                                              (set timer nil)
                                              (set last-notification nil)))))
                        msg)})
