(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)

;; state is a map from name to a table in the following schema:
;;
;; {
;;   pid: number,
;;   diagnostics: { [bufnr: number]: list<diagnostic-structure> },
;;   set-diagnostics: debounce,
;;   ns-id: number,
;;   log-bufnr: number,
;; }
(local state {})

(fn transform-diagnostic [diagnostic]
  (let [bufnr (vim.uri_to_bufnr diagnostic.uri)]
    (tset diagnostic :uri nil)
    (tset diagnostic :bufnr bufnr)
    (when (and diagnostic.col (not diagnostic.end_col))
      (tset diagnostic :end_col (+ diagnostic.col 1)))
    diagnostic))

(fn clear-diagnostics [watcher]
  (let [{: diagnostics : ns-id} watcher]
    (each [bufnr _ (pairs diagnostics)]
      (vim.diagnostic.set ns-id bufnr [])))
  (tset watcher :diagnostics {}))

(fn process-result [log-bufnr name outcome arg]
  (let [watcher (. state name)]
    (match outcome
      :RESET (let [{: diagnostics} watcher]
               (each [bufnr _ (pairs diagnostics)]
                 (tset diagnostics bufnr []))
               (vim.api.nvim_buf_set_lines log-bufnr 0 -2 true []))
      :DIAGNOSTIC (let [diagnostic (transform-diagnostic arg)
                        {: bufnr} diagnostic
                        watcher-diagnostics watcher.diagnostics
                        buf-diagnostics (if-nil (. watcher-diagnostics bufnr)
                                                [])]
                    (table.insert buf-diagnostics diagnostic)
                    (tset watcher-diagnostics bufnr buf-diagnostics)))))

(fn set-diagnostics [name]
  (let [watcher (. state name)]
    (when watcher
      (let [{: ns-id : diagnostics} watcher]
        (each [bufnr buf-diagnostics (pairs diagnostics)]
          (vim.diagnostic.set ns-id bufnr buf-diagnostics))))))

(fn tee [log-bufnr line]
  (vim.api.nvim_buf_set_lines log-bufnr -1 -1 true [line])
  line)

(fn make-chunk-processor [name process-line]
  (var partial-line "")
  (let [{: set-diagnostics : log-bufnr} (. state name)]
    (vim.schedule_wrap (fn [payload]
                         (let [{: chunk : type} payload
                               chunk (if-nil chunk "")]
                           (let [lines (vim.split chunk "\n")]
                             (tset lines 1 (.. partial-line (. lines 1)))
                             (->> lines
                                  (table.remove)
                                  (set partial-line))
                             (each [_ line (ipairs lines)]
                               (->> line
                                    (tee log-bufnr)
                                    (process-line type)
                                    (process-result log-bufnr name)))
                             (set-diagnostics.call)))))))

(fn make-ns [name]
  (let [ns (->> name
                (string.format "fsouza/continous/%s")
                (vim.api.nvim_create_namespace))]
    (vim.diagnostic.config {:underline true
                            :virtual_text false
                            :signs true
                            :update_in_insert false}
                           ns)
    ns))

(lambda stop [name]
  (let [{: pid : set-diagnostics : ns-id : log-bufnr} (if-nil (. state name) {})]
    (when pid
      (vim.loop.kill pid vim.loop.constants.SIGTERM))
    (when set-diagnostics
      (set-diagnostics.stop))
    (when ns-id
      (clear-diagnostics (. state name)))
    (when log-bufnr
      (vim.api.nvim_buf_delete log-bufnr {:force true}))
    (tset state name nil)))

(fn make-scratch-buffer [name]
  (let [bufnr (vim.api.nvim_create_buf false true)]
    (vim.api.nvim_buf_set_name bufnr (string.format "%s - Console Logs" name))
    bufnr))

(lambda start [opts]
  (let [{: name : cmd : args : process-line} opts]
    (stop name)
    (tset state name
          {:diagnostics {}
           :ns-id (make-ns name)
           :log-bufnr (make-scratch-buffer name)
           :set-diagnostics (mod-invoke :fsouza.lib.debounce :debounce 250
                                        #(vim-schedule (set-diagnostics name)))})
    (let [pid (mod-invoke :fsouza.lib.cmd :start cmd {: args}
                          (make-chunk-processor name process-line) #nil)]
      (if pid
          (do
            (tset (. state name) :pid pid)
            (mod-invoke :fsouza.lib.nvim-helpers :augroup
                        (string.format "fsouza__continuous-autokill-%s" name)
                        [{:events [:VimLeavePre]
                          :targets ["*"]
                          :callback #(stop name)}]))
          (stop name)))))

(lambda show-logs [name]
  (let [{: log-bufnr} (if-nil (. state name) {})]
    (when log-bufnr
      (vim.api.nvim_set_current_buf log-bufnr))))

{: start : stop : show-logs}
