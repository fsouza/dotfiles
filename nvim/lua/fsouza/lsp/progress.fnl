(local helpers (require :fsouza.lib.nvim-helpers))

(fn on-progress-update []
  (let [{: notify} (require :fsouza.lib.notif)
        {: mode} (vim.api.nvim_get_mode)]
    (when (= mode :n)
      (fn format-message [msg]
        (var prefix "")
        (var suffix "")
        (when (and (not= msg.title "") (not= msg.title "empty title"))
          (set prefix (string.format "%s: " msg.title)))
        (when (not= msg.name "")
          (set prefix (string.format "[%s] %s" msg.name prefix)))
        (when msg.percentage
          (set suffix (string.format " (%s)" msg.percentage)))
        (string.format "%s%s%s" prefix msg.message suffix))

      (let [messages (vim.lsp.util.get_progress_messages)]
        (each [_ message (ipairs messages)]
          (notify (format-message message)))))))

(fn on-attach []
  (helpers.augroup :fsouza__lsp_progress
                   [{:events [:User]
                     :targets [:LspProgressUpdate]
                     :callback on-progress-update}]))

(fn make-handler []
  (let [debounce (require :fsouza.lib.debounce)
        debounced-handler (debounce.debounce 1000
                                             (vim.schedule_wrap (. vim.lsp.handlers
                                                                   :$/progress)))]
    debounced-handler.call))

{:on-attach (helpers.once on-attach) :handler (make-handler)}
