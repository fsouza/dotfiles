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

(fn reg-key [reg-id client-id]
  (string.format "%d/%s" client-id reg-id))

(fn delete-registration [reg-id client-id]
  (let [reg-key (reg-key reg-id client-id)]
    (tset registrations reg-key nil))
  (each [folder {: event : watchers} (pairs state)]
    (let [watchers (icollect [_ watcher (ipairs watchers)]
                     (if (not= watcher.reg-id reg-id)
                         watcher))]
      (if (= (length watchers) 0)
          (do
            (vim.loop.fs_event_stop event)
            (tset state folder nil))
          (tset state folder {: event : watchers})))))

(fn group-notifications [notifications]
  (let [client-notifications (accumulate [client-notifications {} _ {: client-id
                                                                     : reg-id
                                                                     : uri
                                                                     : type} (ipairs notifications)]
                               (let [reg-key (reg-key reg-id client-id)
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
            (client.notify :workspace/didChangeWatchedFiles {: changes})
            (delete-registration reg-id client-id))))

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
      (when (and (not err) (not (vim.endswith filename backupext))
                 (not (vim.endswith filename :4913)))
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

(fn workspace-folders [client]
  ;; this function uses ?. everywhere because client may be nil.
  (let [folders (icollect [_ {: name} (ipairs (if-nil (?. client :config
                                                          :workspace_folders)
                                                      []))]
                  name)]
    (when (and (= (length folders) 0) (?. client :config :root_dir))
      (table.insert folders client.config.root_dir))
    folders))

(fn register [client-id reg-id watchers]
  (let [notify-server (start-notifier)
        reg-key (reg-key reg-id client-id)]
    (when (not (. registrations reg-key))
      (let [client (vim.lsp.get_client_by_id client-id)
            workspace-folders (workspace-folders client)]
        (tset registrations reg-key true)
        (each [_ workspace-folder (ipairs workspace-folders)]
          (let [glob (require :fsouza.lib.glob)
                entry (if-nil (. state workspace-folder)
                              {:watchers []
                               :event (make-event workspace-folder
                                                  notify-server)})]
            (each [_ watcher (ipairs watchers)]
              (let [(ok pattern) (glob.compile watcher.globPattern)]
                (if ok
                    (table.insert entry.watchers
                                  {: reg-id
                                   : pattern
                                   : client-id
                                   :glob-pattern watcher.globPattern
                                   :kind (if-nil watcher.kind 7)})
                    (error (string.format "error compiling glob from server: %s"
                                          pattern)))))
            (tset state workspace-folder (dedupe-watchers entry))))))))

{: register :unregister delete-registration}
