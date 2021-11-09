(local prefix ["cmd" "ctrl"])

(macro make-hotkey [mod key target]
  `(hs.hotkey.new
     [,mod]
     ,key
     (fn []
       (let [key-event# (hs.eventtap.event.newKeyEvent [] ,target true)]
         (key-event#:post)))
     (fn []
       (let [key-event# (hs.eventtap.event.newKeyEvent [] ,target false)]
         (key-event#:post)))
     (fn []
       (let [key-event# (hs.eventtap.event.newKeyEvent [] ,target true)
             key-event# (key-event#:setProperty hs.eventtap.event.properties.keyboardEventAutorepeat 1)]
         (key-event#:post)))))

(fn set-readline-shortcuts [apps]
  (let [hks [(make-hotkey :ctrl :n :down)
             (make-hotkey :ctrl :p :up)
             (make-hotkey :ctrl :f :right)
             (make-hotkey :ctrl :b :left)]
        filters (icollect [_ app (ipairs apps)]
                  (hs.window.filter.new (fn [win]
                                          (let [application (win:application)]
                                            (= (application:name) app)))))]

    (fn enable-hks []
      (each [_ hk (ipairs hks)]
        (hk:enable)))

    (fn disable-hks []
      (each [_ hk (ipairs hks)]
        (hk:disable)))

    (each [_ filter (ipairs filters)]
      (filter:subscribe hs.window.filter.windowFocused enable-hks)
      (filter:subscribe hs.window.filter.windowUnfocused disable-hks))))

;; prefix+r to reload config
(hs.hotkey.bind prefix "R" (partial hs.reload))

;; prefix+v as a workaround for "typing" the clipboard.
(hs.hotkey.bind prefix "V" (fn []
                             (hs.eventtap.keyStrokes (hs.pasteboard.getContents))))

(set-readline-shortcuts ["Finder" "Firefox" "Safari" "Slack"])
