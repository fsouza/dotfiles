(import-macros {: mod-invoke} :helpers)

(fn fmt-task [task-name message percentage]
  (let [mid (if percentage
                (string.format " (%s%%)" percentage)
                "")
        suffix (if (and task-name (not= task-name ""))
                   (string.format " [%s]" task-name)
                   "")]
    (.. message mid suffix)))

(mod-invoke :fidget :setup {:window {:blend 0} :fmt {:task fmt-task}})
