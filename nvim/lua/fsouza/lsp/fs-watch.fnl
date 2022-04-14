(import-macros {: if-nil : mod-invoke : abuf} :helpers)

(local watch-kind {:Create 1 :Change 2 :Delete 4})

(local file-change-type {:Created 1 :Changed 2 :Deleted 3})

;; The variable "state" maps a folder to a table in the following shape:
;;
;; {
;;   : event ;; the luv event handler
;;   : watchers ;; list of Watcher (see shape below)
;; }
;;
;; The shape for the watcher is:
;;
;; {
;;   : client-id ;; the client-id that registered this watcher
;;   : pattern ;; pattern for this watcher
;;   : kind ;; kind of events of interest
;; }
;;
;; The watcher is mostly derived directly from LSP, with naming conventions
;; adjusted:
;; - https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#fileSystemWatcher
(local state {})

;; index from client-id -> set of registrations, just to dedupe notifications.
(local registrations {})

(fn delete-client [client-id]
  (each [folder {: event : watchers} (pairs state)]
    (let [watchers (icollect [_ watcher (ipairs watchers)]
                     (if (not= watcher.client-id client-id)
                         watcher))]
      (if (= (length watchers) 0)
          (do
            (event:close)
            (tset state folder nil))
          (tset state folder {: event : watchers})))))

(fn make-notifier [root-dir]
  (let [backupext vim.o.backupext]
    ;; TODO: use a timer or something like to batch notifications (will require
    ;; deduping).
    (let [tablex (require :fsouza.tablex)
          pl-path (require :pl.path)
          glob (require :fsouza.lib.glob)
          buffers (require :fsouza.plugin.buffers)]
      (fn notify [client-id filepath events kind]
        (fn notify-server [client uri type ordinal]
          (when (not= (bit.band kind ordinal) 0)
            (client.notify :workspace/didChangeWatchedFiles
                           {:changes [{: uri : type}]})))

        (let [client (vim.lsp.get_client_by_id client-id)]
          (if client
              (let [uri (vim.uri_from_fname filepath)]
                (assert (= root-dir client.config.root_dir))
                (if events.rename
                    (vim.loop.fs_stat filepath
                                      #(if $1
                                           (notify-server client uri
                                                          file-change-type.Deleted
                                                          watch-kind.Delete)
                                           (if (buffers.has-file filepath)
                                               (notify-server client uri
                                                              file-change-type.Changed
                                                              watch-kind.Change)
                                               (notify-server client uri
                                                              file-change-type.Created
                                                              watch-kind.Create))))
                    (notify-server client uri file-change-type.Changed
                                   watch-kind.Change)))
              (delete-client client-id))))

      (fn [err filename events]
        (when (and (not err) (not (vim.endswith filename backupext)))
          (let [filepath (->> filename
                              (pl-path.join root-dir)
                              (pl-path.abspath))
                {: watchers} (. state root-dir)]
            (each [_ {: pattern : client-id : kind} (ipairs watchers)]
              (when (or (glob.match pattern filename)
                        (glob.match pattern filepath))
                (notify client-id filepath events kind)))))))))

(fn make-event [root-dir]
  (let [event (vim.loop.new_fs_event)
        (ok err) (event:start root-dir {:recursive true}
                              (make-notifier root-dir))]
    (when (not ok)
      (error err))
    event))

(fn dedupe-watchers [entry]
  ;; TODO: find a less dumb way of doing this.
  (let [unique-watchers {}]
    (each [_ watcher (ipairs entry.watchers)]
      (tset unique-watchers (vim.inspect watcher) watcher))
    (tset entry :watchers (vim.tbl_values unique-watchers))
    entry))

(fn register [client-id reg-id watchers]
  (when (not (?. registrations client-id reg-id))
    (let [client-registrations (if-nil (. registrations client-id) {})
          client (vim.lsp.get_client_by_id client-id)]
      (tset client-registrations reg-id true)
      (tset registrations client-id client-registrations)
      (when (and client client.config.root_dir)
        (let [glob (require :fsouza.lib.glob)
              root-dir client.config.root_dir
              entry (if-nil (. state root-dir)
                            {:watchers [] :event (make-event root-dir)})]
          (each [_ watcher (ipairs watchers)]
            (let [(ok pattern) (glob.compile watcher.globPattern)]
              (if ok
                  (table.insert entry.watchers
                                {: pattern
                                 : client-id
                                 :kind (if-nil watcher.kind 7)})
                  (error (string.format "error compiling glob from server: %s"
                                        pattern)))))
          (tset state root-dir (dedupe-watchers entry)))))))

(fn unregister [client-id reg-id]
  (delete-client client-id)
  (let [client-registrations (if-nil (. registrations client-id) {})]
    (tset client-registrations reg-id nil)
    (tset registrations client-id client-registrations)))

{: register : unregister}
