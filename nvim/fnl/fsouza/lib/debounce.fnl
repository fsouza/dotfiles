(fn debounce [interval-ms f]
  (var last-call nil)
  (let [timer (vim.loop.new_timer)
        make-call (fn []
                    (when last-call
                      (f (unpack last-call))
                      (set last-call nil)))]
    (timer:start interval-ms interval-ms make-call)
    {:call (fn [...] (set last-call [...]))
     :stop (fn []
             (make-call)
             (timer:close))}))

{:debounce debounce}
