(import-macros {: if-nil : mod-invoke : abuf : vim-schedule} :helpers)

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
;;   : reg-id ;; the id of the registration that added this watcher
;;   : client-id ;; the client-id that registered this watcher
;;   : pattern ;; pattern for this watcher
;;   : kind ;; kind of events of interest
;; }
(local state {})

(local registrations {})

(fn delete-registration [reg-id]
  (each [folder {: event : watchers} (pairs state)]
    (let [watchers (icollect [_ watcher (ipairs watchers)]
                     (if (not= watcher.reg-id reg-id)
                         watcher))]
      (if (= (length watchers) 0)
          (do
            (vim.loop.fs_event_stop event)
            (tset state folder nil))
          (tset state folder {: event : watchers})))))

(fn reg-key [client-id reg-id]
  (string.format "%d/%s" client-id reg-id))

(fn group-notifications [notifications]
  (let [client-notifications (accumulate [client-notifications {} _ {: client-id
                                                                     : reg-id
                                                                     : uri
                                                                     : type} (ipairs notifications)]
                               (let [reg-key (reg-key client-id reg-id)
                                     client-notification (if-nil (. client-notifications
                                                                    reg-key)
                                                                 {: client-id
                                                                  : reg-id
                                                                  :changes {}})]
                                 (tset client-notification.changes uri type)
                                 (tset client-notifications reg-key
                                       client-notification)
                                 client-notifications))]
    (icollect [_ {: changes : client-id : reg-id} (pairs client-notifications)]
      {: client-id
       : reg-id
       :changes (icollect [uri type (pairs changes)]
                  {: uri : type})})))

(fn start-notifier [interval-ms]
  (var notifications [])
  (let [interval-ms (if-nil interval-ms 200)
        timer (vim.loop.new_timer)]
    (fn notify [client-id reg-id changes]
      (let [client (vim.lsp.get_client_by_id client-id)]
        (if client
            (do
              (print "sending notification " client-id (vim.inspect changes))
              (client.notify :workspace/didChangeWatchedFiles {: changes}))
            (delete-registration reg-id))))

    (fn timer-cb []
      (let [client-notifications (group-notifications notifications)]
        (set notifications [])
        (each [_ {: client-id : reg-id : changes} (pairs client-notifications)]
          (vim-schedule (notify client-id reg-id changes)))))

    (vim.loop.timer_start timer interval-ms interval-ms timer-cb)
    (fn [client-id reg-id uri type]
      (table.insert notifications {: client-id : reg-id : uri : type}))))

(local start-notifier
       (mod-invoke :fsouza.lib.nvim-helpers :once start-notifier))

(fn make-fs-event-handler [root-dir notify-server]
  (let [backupext vim.o.backupext
        tablex (require :fsouza.tablex)
        pl-path (require :pl.path)
        glob (require :fsouza.lib.glob)
        buffers (require :fsouza.plugin.buffers)]
    (fn notify [client-id reg-id filepath events kind]
      (fn try-notify-server [client-id reg-id uri type ordinal]
        (when (not= (bit.band kind ordinal) 0)
          (notify-server client-id reg-id uri type)))

      (let [uri (vim.uri_from_fname filepath)]
        (if events.rename
            (vim.loop.fs_stat filepath
                              #(if $1
                                   (try-notify-server client-id reg-id uri
                                                      file-change-type.Deleted
                                                      watch-kind.Delete)
                                   (if (buffers.has-file filepath)
                                       (try-notify-server client-id reg-id uri
                                                          file-change-type.Changed
                                                          watch-kind.Change)
                                       (try-notify-server client-id reg-id uri
                                                          file-change-type.Created
                                                          watch-kind.Create))))
            (try-notify-server client-id reg-id uri file-change-type.Changed
                               watch-kind.Change))))

    (fn [err filename events]
      (when (and (not err) (not (vim.endswith filename backupext)))
        (let [filepath (->> filename
                            (pl-path.join root-dir)
                            (pl-path.abspath))
              {: watchers} (. state root-dir)]
          (each [_ {: pattern : client-id : kind : reg-id} (ipairs watchers)]
            (when (or (glob.match pattern filename)
                      (glob.match pattern filepath))
              (notify client-id reg-id filepath events kind))))))))

(fn make-event [root-dir notify-server]
  (let [event (vim.loop.new_fs_event)
        (ok err) (vim.loop.fs_event_start event root-dir {:recursive true}
                                          (make-fs-event-handler root-dir
                                                                 notify-server))]
    (when (not ok)
      (error err))
    event))

(fn dedupe-watchers [entry]
  (let [unique-watchers {}]
    (each [_ watcher (ipairs entry.watchers)]
      (tset unique-watchers (vim.inspect watcher) watcher))
    (tset entry :watchers (vim.tbl_values unique-watchers))
    entry))

(fn register [client-id reg-id watchers]
  (let [notify-server (start-notifier)
        reg-key (reg-key client-id reg-id)]
    (when (not (?. registrations reg-key))
      (let [client-registrations (if-nil (. registrations client-id) {})
            client (vim.lsp.get_client_by_id client-id)]
        (tset registrations reg-key true)
        (when (and client client.config.root_dir)
          (let [glob (require :fsouza.lib.glob)
                root-dir client.config.root_dir
                entry (if-nil (. state root-dir)
                              {:watchers []
                               :event (make-event root-dir notify-server)})]
            (each [_ watcher (ipairs watchers)]
              (let [(ok pattern) (glob.compile watcher.globPattern)]
                (if ok
                    (table.insert entry.watchers
                                  {: reg-id
                                   : pattern
                                   : client-id
                                   :kind (if-nil watcher.kind 7)})
                    (error (string.format "error compiling glob from server: %s"
                                          pattern)))))
            (tset state root-dir (dedupe-watchers entry))))))))

(fn unregister [client-id reg-id]
  (let [reg-key (reg-key client-id reg-id)]
    (tset registrations reg-key nil))
  (delete-registration reg-id))

{: register : unregister}
