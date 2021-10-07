(local prefix ["cmd" "ctrl"])

;; prefix+r to reload config
(hs.hotkey.bind prefix "R" (partial hs.reload))

;; prefix+v as a workaround for "typing" the clipboard.
(hs.hotkey.bind prefix "V" (fn []
                             (hs.eventtap.keyStrokes (hs.pasteboard.getContents))))
