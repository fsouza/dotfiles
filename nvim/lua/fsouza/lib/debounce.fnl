(lambda debounce [interval-ms f]
  (var last-call nil)
  (let [timer (vim.uv.new_timer)]
    (fn make-call []
      (when last-call
        (f (unpack last-call))
        (set last-call nil)))

    (timer:start interval-ms interval-ms make-call)
    {:call #(set last-call [$...])
     :stop #(do
              (timer:close)
              (set last-call nil))}))

{: debounce}
