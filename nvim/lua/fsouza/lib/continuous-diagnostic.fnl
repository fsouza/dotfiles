(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)

;; state is a map from name to a table in the following schema:
;;
;; {
;;   pid: number,
;;   diagnostics: { [bufnr: number]: list<diagnostic-structure> },
;;   set-diagnostics: debounce,
;;   ns-id: number,
;; }
(local state {})

(lambda transform-diagnostic [diagnostic]
  (let [bufnr (vim.uri_to_bufnr diagnostic.uri)]
    (tset diagnostic :uri nil)
    (tset diagnostic :bufnr bufnr)
    diagnostic))

(fn process-result [name outcome arg]
  (let [watcher (. state name)]
    (match outcome
      :RESET (do
               (let [{: diagnostics : ns-id} watcher]
                 (each [bufnr _ (pairs diagnostics)]
                   (vim.diagnostic.set ns-id bufnr [])))
               (tset watcher :diagnostics {}))
      :DIAGNOSTIC (let [diagnostic (transform-diagnostic arg)
                        {: bufnr} diagnostic
                        watcher-diagnostics watcher.diagnostics
                        buf-diagnostics (if-nil (. watcher-diagnostics bufnr)
                                                [])]
                    (table.insert buf-diagnostics diagnostic)
                    (tset watcher-diagnostics bufnr buf-diagnostics)))))

(lambda set-diagnostics [name]
  (let [watcher (. state name)]
    (when watcher
      (let [{: ns-id : diagnostics} watcher]
        (each [bufnr buf-diagnostics (pairs diagnostics)]
          (vim.diagnostic.set ns-id bufnr buf-diagnostics))))))

(lambda make-chunk-processor [name process-line]
  (var partial-line "")
  (let [{: set-diagnostics} (. state name)]
    (vim.schedule_wrap (fn [payload]
                         (let [{: chunk : type} payload
                               chunk (if-nil chunk "")]
                           (let [lines (vim.split chunk "\n")]
                             (tset lines 1 (.. partial-line (. lines 1)))
                             (->> lines
                                  (table.remove)
                                  (set partial-line))
                             (each [_ line (ipairs lines)]
                               (->> (process-line line type)
                                    (process-result name)))
                             (set-diagnostics.call)))))))

(lambda stop [name]
  (let [{: pid : set-diagnostics} (if-nil (. state name) {})]
    (when pid
      (vim.loop.kill pid vim.loop.constants.SIGTERM))
    (when set-diagnostics
      (set-diagnostics.stop))
    (tset state name nil)))

(lambda make-ns [name]
  (let [ns (->> name
                (string.format "fsouza/continous/%s")
                (vim.api.nvim_create_namespace))]
    (vim.diagnostic.config {:underline true
                            :virtual_text false
                            :signs true
                            :update_in_insert false}
                           ns)
    ns))

(fn start [opts]
  (let [{: name : cmd : args : process-line} opts]
    (stop name)
    (tset state name
          {:diagnostics {}
           :ns-id (make-ns name)
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

{: start : stop}
