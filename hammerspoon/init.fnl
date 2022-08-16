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
  (fn check-window [window]
    (let [application (window:application)
          app-name (if application
                       (application:name)
                       "")
          app-name (string.lower app-name)]
      (fn check-app [idx]
        (if (> idx (length opt-out-apps)) false
            (let [app (. opt-out-apps idx)]
              (if (= app app-name) true (check-app (+ idx 1))))))

      (check-app 1)))

  (let [hks [(make-hotkey :ctrl :n [] :down)
             (make-hotkey :ctrl :p [] :up)
             (make-hotkey :ctrl :f [] :right)
             (make-hotkey :ctrl :b [] :left)
             (make-hotkey :ctrl :w [:alt] hs.keycodes.map.delete)
             (make-hotkey :ctrl :u [:cmd] hs.keycodes.map.delete)]
        filter (hs.window.filter.new check-window)]
    (fn enable-hks []
      (each [_ hk (ipairs hks)]
        (hk:enable)))

    (fn disable-hks []
      (each [_ hk (ipairs hks)]
        (hk:disable)))

    (filter:subscribe hs.window.filter.windowFocused disable-hks)
    (filter:subscribe hs.window.filter.windowUnfocused enable-hks)
    (if (not (check-window (hs.window.focusedWindow)))
        (enable-hks))))

(let [prefix [:cmd :ctrl]]
  (hs.hotkey.bind prefix :R hs.reload)
  (hs.hotkey.bind prefix :V
                  #(hs.eventtap.keyStrokes (hs.pasteboard.getContents))))

(set-readline-shortcuts [:alacritty :kitty :terminal :wezterm])
