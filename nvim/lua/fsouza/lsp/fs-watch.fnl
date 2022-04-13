(import-macros {: if-nil : mod-invoke : abuf} :helpers)

(local client-watchers {})

(local watch-kind {:Create 1 :Change 2 :Delete 4})

(local file-change-type {:Created 1 :Changed 2 :Deleted 3})

(fn delete-client [client-id]
  (let [event (. client-watchers client-id)]
    (when event
      (event:close)
      (tset client-watchers client-id nil))))

(fn make-notifier [client-id path kind]
  (let [backupext vim.o.backupext]
    (fn notify-server [client uri type ordinal]
      (when (not= (bit.band kind ordinal) 0)
        (client.notify :workspace/didChangeWatchedFiles
                       {:changes [{: uri : type}]})))

    (let [pl-path (require :pl.path)
          buffers (require :fsouza.plugin.buffers)]
      (fn [err filename events]
        (when (and (not err) (not (vim.endswith filename backupext)))
          (let [client (vim.lsp.get_client_by_id client-id)]
            (if client
                (let [filepath (->> filename
                                    (pl-path.join path)
                                    (pl-path.abspath))
                      uri (vim.uri_from_fname filepath)]
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
                (delete-client client-id))))))))

;; TODO: implement filters based on the provided globPattern.
;;
;; The idea is that we're going to have one fs-event per root_dir, and then
;; filter the events based on the globPatterns.
(fn register [client-id watchers]
  (when (not (. client-watchers client-id))
    (let [client (vim.lsp.get_client_by_id client-id)]
      (when (and client client.config.root_dir)
        (let [(_ watcher) (mod-invoke :fsouza.tablex :find_if watchers
                                      #(if (= $1.globPattern "**")
                                           $1))]
          (when watcher
            (let [path client.config.root_dir
                  event (vim.loop.new_fs_event)
                  (ok _) (event:start path {:recursive true}
                                      (make-notifier client-id path
                                                     (if-nil watcher.kind 7)))]
              (when ok
                (tset watchers client-id event)))))))))

{: register :unregister delete-client}
