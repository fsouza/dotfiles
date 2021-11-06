(local prefix ["cmd" "ctrl"])

(fn set-readline-shortcuts [apps]
  (let [hks [(hs.hotkey.new [:ctrl] :n (partial hs.eventtap.keyStroke [] :down))
             (hs.hotkey.new [:ctrl] :p (partial hs.eventtap.keyStroke [] :up))
             (hs.hotkey.new [:ctrl] :f (partial hs.eventtap.keyStroke [] :right))
             (hs.hotkey.new [:ctrl] :b (partial hs.eventtap.keyStroke [] :left))]
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

; (hs.hotkey.bind ["ctrl"] "n" (partial hs.eventtap.keyStroke [] :down))
; (hs.hotkey.bind ["ctrl"] "p" (partial hs.eventtap.keyStroke [] :up))

;; prefix+r to reload config
(hs.hotkey.bind prefix "R" (partial hs.reload))

;; prefix+v as a workaround for "typing" the clipboard.
(hs.hotkey.bind prefix "V" (fn []
                             (hs.eventtap.keyStrokes (hs.pasteboard.getContents))))

(set-readline-shortcuts ["Finder" "Firefox" "Safari" "Slack"])
