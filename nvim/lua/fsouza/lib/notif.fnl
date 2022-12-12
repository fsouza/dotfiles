(var last-notification nil)

(var messages [])

(var timer nil)

(macro max-width []
  13)

(fn trim [msg]
  (let [width (- (max-width) 3)]
    (.. (string.sub msg 1 width) "...")))

(fn record-message [msg]
  (when (< (length messages) 100)
    (table.insert messages {: msg :date (os.date "%b %d, %H:%M:%S")})))

(lambda notify [notification]
  (record-message notification.msg)
  (let [msg notification.msg
        msg (if (> (length msg) (max-width))
                (trim msg)
                msg)]
    (set last-notification {: msg :age notification.age}))
  (when (not= timer nil)
    (timer:stop)
    (timer:close)
    (set timer nil)))

(lambda get-notification []
  (if last-notification
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
        msg)
      ""))

(lambda log-messages []
  (each [_ {: msg : date} (ipairs messages)]
    (print (string.format "%s - %s" date msg)))
  (set messages []))

{: notify : get-notification : log-messages}
