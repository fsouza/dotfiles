(import-macros {: mod-invoke} :helpers)

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
            (vim.uv.fs_event_stop event)
            (tset state folder nil))
          (tset state folder {: event : watchers})))))

(fn start-notifier [interval-ms]
  (var client-notifications {})
  (let [interval-ms (or interval-ms 200)
        timer (vim.uv.new_timer)]
    (fn notify [client-id reg-id changes]
      (let [client (vim.lsp.get_client_by_id client-id)]
        (if client
            (client.notify :workspace/didChangeWatchedFiles {: changes})
            (delete-registration reg-id client-id))))

    (fn timer-cb []
      (each [_ {: client-id : reg-id : changes} (pairs client-notifications)]
        (let [changes (icollect [uri type (pairs changes)]
                        {: uri : type})]
          (vim.schedule #(notify client-id reg-id changes))))
      (set client-notifications {}))

    (vim.uv.timer_start timer interval-ms interval-ms timer-cb)
    (fn [client-id reg-id uri type]
      (let [reg-key (reg-key reg-id client-id)
            client-notification (or (. client-notifications reg-key)
                                    {: client-id : reg-id :changes {}})]
        (tset client-notification.changes uri type)
        (tset client-notifications reg-key client-notification)))))

(local start-notifier
       (mod-invoke :fsouza.lib.nvim-helpers :once start-notifier))

(fn is-file-open [filepath]
  (let [path (require :fsouza.pl.path)]
    (-> (vim.api.nvim_list_bufs)
        (vim.iter)
        (: :filter vim.api.nvim_buf_is_loaded)
        (: :map #(let [bufname (vim.api.nvim_buf_get_name $1)]
                   (path.abspath bufname)))
        (: :any #(= $1 filepath)))))

(fn make-fs-event-handler [root-dir notify-server]
  (let [backupext vim.o.backupext
        pl-path (require :fsouza.pl.path)
        glob (require :fsouza.lib.glob)]
    (fn notify [client-id reg-id filepath events kind]
      (fn try-notify-server [client-id reg-id uri type ordinal]
        (when (not= (band kind ordinal) 0)
          (notify-server client-id reg-id uri type)))

      (let [uri (vim.uri_from_fname filepath)]
        (if events.rename
            (vim.uv.fs_stat filepath
                            #(if $1
                                 (try-notify-server client-id reg-id uri
                                                    file-change-type.Deleted
                                                    watch-kind.Delete)
                                 (vim.schedule #(if (is-file-open filepath)
                                                    (try-notify-server client-id
                                                                       reg-id
                                                                       uri
                                                                       file-change-type.Changed
                                                                       watch-kind.Change)
                                                    (try-notify-server client-id
                                                                       reg-id
                                                                       uri
                                                                       file-change-type.Created
                                                                       watch-kind.Create)))))
            (try-notify-server client-id reg-id uri file-change-type.Changed
                               watch-kind.Change))))

    (fn [err filename events]
      (when (and (not err) (not (vim.endswith filename backupext))
                 (not (vim.startswith filename :.git/))
                 (not (vim.startswith filename :.hg/))
                 (not (vim.endswith filename :4913)))
        (let [filepath (->> filename
                            (pl-path.join root-dir)
                            (pl-path.abspath))
              {: watchers} (. state root-dir)]
          (each [_ {: pattern : client-id : kind : reg-id} (ipairs watchers)]
            (when (or (glob.match pattern filename)
                      (glob.match pattern filepath))
              (vim.schedule #(notify client-id reg-id filepath events kind)))))))))

(fn make-event [root-dir notify-server]
  (let [event (vim.uv.new_fs_event)
        (ok err) (vim.uv.fs_event_start event root-dir {:recursive true}
                                        (make-fs-event-handler root-dir
                                                               notify-server))]
    (when (not ok)
      (error (string.format "failed to start fsevent at %s: %s" root-dir err)))
    event))

(fn dedupe-watchers [entry]
  (let [unique-watchers {}]
    (each [_ watcher (ipairs entry.watchers)]
      (tset unique-watchers (vim.inspect watcher) watcher))
    (tset entry :watchers (vim.tbl_values unique-watchers))
    entry))

(fn workspace-folders [client]
  (icollect [_ {: name} (ipairs (or (?. client :workspace_folders) []))]
    name))

(fn map-watchers [client watchers]
  (let [glob (require :fsouza.lib.glob)
        path (require :fsouza.pl.path)
        folders (collect [_ folder (ipairs (workspace-folders client))]
                  (values folder []))
        abs-folders []]
    (each [_ watcher (ipairs watchers)]
      (let [pats (glob.break watcher.globPattern)
            sample (. pats 1)]
        (var is-abs (path.isabs sample))
        (each [folder _ (pairs folders)]
          (when (path.isrel sample folder)
            (table.insert (. folders folder) watcher)
            (set is-abs false)))
        (when is-abs
          (each [folder _ (pairs state)]
            (when (path.isrel sample folder)
              (tset folders folder [watcher])
              (set is-abs false)))
          (when is-abs
            (table.insert abs-folders {: watcher : pats})))))

    (fn find-best-folder [folder]
      (let [existing (-> folders
                         (vim.iter)
                         (: :filter #(path.isrel folder $1))
                         (: :next))]
        (fn find-existing [folder]
          (let [(_ err) (vim.uv.fs_stat folder)]
            (if err
                (find-existing (vim.fs.dirname folder))
                folder)))

        (or existing (find-existing folder))))

    (each [_ {: pats : watcher} (ipairs abs-folders)]
      (each [_ pat (ipairs pats)]
        (let [pat (glob.strip-special pat)
              folder (find-best-folder pat)
              watchers (or (. folders folder) [])]
          (table.insert watchers watcher)
          (tset folders folder watchers))))
    folders))

(fn register [client-id reg-id watchers]
  (let [notify-server (start-notifier)
        reg-key (reg-key reg-id client-id)]
    (when (not (. registrations reg-key))
      (let [client (vim.lsp.get_client_by_id client-id)
            folder-map (map-watchers client watchers)]
        (tset registrations reg-key true)
        (each [folder watchers (pairs folder-map)]
          (let [glob (require :fsouza.lib.glob)
                entry (or (. state folder)
                          {:watchers []
                           :event (make-event folder notify-server)})]
            (each [_ watcher (ipairs watchers)]
              (let [(ok pattern) (glob.compile watcher.globPattern)]
                (if ok
                    (table.insert entry.watchers
                                  {: reg-id
                                   : pattern
                                   : client-id
                                   :glob-pattern watcher.globPattern
                                   :kind (or watcher.kind 7)})
                    (error (string.format "error compiling glob from server: %s"
                                          pattern)))))
            (tset state folder (dedupe-watchers entry))))))))

{: register :unregister delete-registration}
