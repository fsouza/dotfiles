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

(fn set-readline-shortcuts [terminal-apps]
  (fn is-terminal [window]
    (if (not window) false (let [application (window:application)
                                 app-name (if application
                                              (application:name)
                                              "")
                                 app-name (string.lower app-name)]
                             (fn check-app [idx]
                               (if (> idx (length terminal-apps)) false
                                   (let [app (. terminal-apps idx)]
                                     (if (= app app-name) true
                                         (check-app (+ idx 1))))))

                             (check-app 1))))

  (let [hks [(make-hotkey :ctrl :n [] :down)
             (make-hotkey :ctrl :p [] :up)
             (make-hotkey :ctrl :f [] :right)
             (make-hotkey :ctrl :b [] :left)
             (make-hotkey :ctrl :w [:alt] hs.keycodes.map.delete)
             (make-hotkey :ctrl :u [:cmd] hs.keycodes.map.delete)]
        terminal-filter (hs.window.filter.new is-terminal)
        not-terminal-filter (hs.window.filter.new #(not (is-terminal $1)))]
    (fn enable-hks []
      (each [_ hk (ipairs hks)]
        (hk:enable)))

    (fn disable-hks []
      (each [_ hk (ipairs hks)]
        (hk:disable)))

    (terminal-filter:subscribe hs.window.filter.windowFocused disable-hks)
    (not-terminal-filter:subscribe hs.window.filter.windowFocused enable-hks)
    (if (not (is-terminal (hs.window.focusedWindow)))
        (enable-hks))))

(let [prefix [:cmd :ctrl]]
  (hs.hotkey.bind prefix :R hs.reload)
  (hs.hotkey.bind prefix :V
                  #(hs.eventtap.keyStrokes (hs.pasteboard.getContents))))

(set-readline-shortcuts [:alacritty :terminal])
