(import-macros {: vim-schedule} :helpers)

(fn make-debug [prefix debug-fn]
  (if (= debug-fn nil)
    (fn [] nil)
    (fn [data]
      (let [lines (vim.split data "\n")]
        (each [_ line (ipairs lines)]
          (when (not= line "")
            (debug-fn (string.format "%s: %s" prefix line))))))))

(fn input-collector [prefix debug-fn]
  (let [debug (make-debug prefix debug-fn)
        result {:data ""}]
    (tset result :callback (fn [err chunk]
                             (when err
                               (tset result :err err))
                             (when chunk
                               (tset result :data (.. result.data chunk))
                               (debug chunk))))
    result))

(fn safe-close [h cb]
  (when (not (vim.loop.is_closing h))
    (vim.loop.close h cb)))

;; run takes the given command, args and input_data (used as stdin for the
;; child process).
;;
;; The last parameter is a callback that will be invoked whenever the command
;; finishes, the callback receives a table in the following shape:
;;
;; {
;;   stdout: string;
;;   stderr: string;
;;   exit-status: number;
;;   signal: number;
;;   errors: string table;
;; }
(fn run [cmd opts input-data on-finished debug-fn]
  (var cmd-handle nil)
  (let [loop vim.loop
        stdout (loop.new_pipe false)
        stderr (loop.new_pipe false)
        stdin (loop.new_pipe false)
        close (fn []
                (loop.read_stop stdout)
                (loop.read_stop stderr)
                (safe-close stdout)
                (safe-close stderr)
                (safe-close stdin)
                (safe-close cmd-handle))
        stdout-handler (input-collector "STDOUT" debug-fn)
        stderr-handler (input-collector "STDERR" debug-fn)
        r {:abort false :finished false}
        on-exit (fn [code signal]
                  (let [code (if (and r.abort (= code 0))
                               -1
                               code)]
                    (vim-schedule
                      (let [errors []]
                        (when stdout-handler.err
                          (table.insert errors stdout-handler.err))
                        (when stderr-handler.err
                          (table.insert errors stderr-handler.err))

                        (on-finished {:exit-status code
                                      :aborted r.abort
                                      :signal signal
                                      :stdout stdout-handler.data
                                      :stderr stderr-handler.data
                                      :errors errors})
                        (tset r :finished true)
                        (close)))))
        opts (vim.tbl_extend "error" opts {:stdio [stdin stdout stderr]})
        (spawn-handle pid-or-err) (loop.spawn cmd opts on-exit)]

    (if spawn-handle
      (do
        (set cmd-handle spawn-handle)
        (loop.read_start stdout stdout-handler.callback)
        (loop.read_start stderr stderr-handler.callback)
        (when input-data
          (loop.write stdin input-data))
        (loop.shutdown stdin))
      (vim-schedule (on-finished {:exit-status -1 :stderr pid-or-err})))))

{: run}
