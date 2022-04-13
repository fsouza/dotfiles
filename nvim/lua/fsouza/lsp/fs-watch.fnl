(import-macros {: if-nil : mod-invoke : abuf} :helpers)

(local client-watchers {})

(local watch-kind {:Create 1 :Change 2 :Delete 4})

(local file-change-type {:Created 1 :Changed 2 :Deleted 3})

(local all-files {})

(fn delete-client [client-id]
  (let [event (. client-watchers client-id)]
    (when event
      (event:close)
      (tset client-watchers client-id nil))))

(fn is-change [events filepath]
  (if events.rename
      (not= (. all-files filepath) nil)
      true))

(fn make-notifier [client-id path kind]
  (fn notify-server [client uri type ordinal]
    (when (not= (bit.band kind ordinal) 0)
      (client.notify :workspace/didChangeWatchedFiles
                     {:changes [{: uri : type}]})))

  (let [pl-path (require :pl.path)]
    (fn [err filename events]
      (when (and (not err) (not (vim.endswith filename "~")))
        (let [client (vim.lsp.get_client_by_id client-id)]
          (if client
              (let [filepath (->> filename
                                  (pl-path.join path)
                                  (pl-path.abspath))
                    uri (vim.uri_from_fname filepath)]
                (if (is-change events filepath)
                    (notify-server client uri file-change-type.Changed
                                   watch-kind.Change)
                    (vim.loop.fs_stat filepath
                                      #(if $1
                                           (notify-server client uri
                                                          file-change-type.Deleted
                                                          watch-kind.Delete)
                                           (notify-server client uri
                                                          file-change-type.Created
                                                          watch-kind.Create)))))
              (delete-client client-id)))))))

(fn set-from-bufnr [bufnr v]
  (let [bufname (vim.api.nvim_buf_get_name bufnr)]
    (when (not= bufname "")
      (let [path (require :pl.path)
            filepath (path.abspath bufname)]
        (tset all-files filepath v)))))

(fn set-afile [v]
  (let [bufnr (abuf)]
    (when bufnr
      (set-from-bufnr bufnr v))))

(fn record-buffer []
  (set-afile true))

(fn handle-BufDelete []
  (set-afile nil))

(local create-augroup
       (mod-invoke :fsouza.lib.nvim-helpers :once
                   #(mod-invoke :fsouza.lib.nvim-helpers :augroup
                                :fsouza__lsp__fs-watch
                                [{:events [:BufNewFile :BufReadPost]
                                  :targets ["*"]
                                  :callback record-buffer}
                                 {:events [:BufDelete]
                                  :targets ["*"]
                                  :callback handle-BufDelete}])))

(local register-buffers
       (mod-invoke :fsouza.lib.nvim-helpers :once
                   #(let [bufs (vim.api.nvim_list_bufs)]
                      (each [_ bufnr (ipairs bufs)]
                        (set-from-bufnr bufnr true)))))

;; TODO: implement filters based on the provided globPattern.
;;
;; The idea is that we're going to have one fs-event per root_dir, and then
;; filter the events based on the globPatterns.
(fn register [client-id watchers]
  (create-augroup)
  (register-buffers)
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
