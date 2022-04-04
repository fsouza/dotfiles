(var last-notification nil)

(var timer nil)

(fn notify [notification]
  (set last-notification notification)
  (when (not= timer nil)
    (timer:stop)
    (timer:close)
    (set timer nil)))

(fn get-notification []
  (let [{: msg : age} last-notification]
    (if (= timer nil)
        (do
          (set timer (vim.loop.new_timer))
          (timer:start age 0
                       #(do
                          (timer:stop)
                          (timer:close)
                          (set timer nil)
                          (set last-notification nil)))))
    msg))

{: notify :has-notification #(not= last-notification nil) : get-notification}
