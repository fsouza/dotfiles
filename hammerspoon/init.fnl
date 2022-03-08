(macro make-hotkey [mod key mod-target target]
  `(hs.hotkey.new [,mod] ,key
                  #(let [key-event# (hs.eventtap.event.newKeyEvent ,mod-target
                                                                   ,target true)]
                     (key-event#:post))
                  #(let [key-event# (hs.eventtap.event.newKeyEvent ,mod-target
                                                                   ,target false)]
                     (key-event#:post))
                  #(let [key-event# (hs.eventtap.event.newKeyEvent ,mod-target
                                                                   ,target true)]
                     (key-event#:post))))

(fn set-readline-shortcuts [opt-out-apps]
  (let [hks [(make-hotkey :ctrl :n [] :down)
             (make-hotkey :ctrl :p [] :up)
             (make-hotkey :ctrl :f [] :right)
             (make-hotkey :ctrl :b [] :left)
             (make-hotkey :ctrl :w [:alt] hs.keycodes.map.delete)
             (make-hotkey :ctrl :u [:cmd] hs.keycodes.map.delete)]
        filters (icollect [_ app (ipairs opt-out-apps)]
                  (hs.window.filter.new #(let [application ($1:application)
                                               app-name (if application
                                                            (application:name)
                                                            nil)]
                                           (= app-name app))))]
    (fn enable-hks []
      (each [_ hk (ipairs hks)]
        (hk:enable)))

    (fn disable-hks []
      (each [_ hk (ipairs hks)]
        (hk:disable)))

    (each [_ filter (ipairs filters)]
      (filter:subscribe hs.window.filter.windowFocused disable-hks)
      (filter:subscribe hs.window.filter.windowUnfocused enable-hks))))

(let [prefix [:cmd :ctrl]]
  (hs.hotkey.bind prefix :R (partial hs.reload))
  (hs.hotkey.bind prefix :V
                  #(hs.eventtap.keyStrokes (hs.pasteboard.getContents))))

(set-readline-shortcuts [:Alacritty :Terminal])
