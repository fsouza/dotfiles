(local debounce (require "fsouza.lib.debounce"))
(local helpers (require "fsouza.lib.nvim_helpers"))

(local debounced-notify (debounce.debounce 4000 (vim.schedule_wrap vim.notify)))

(fn on-progress-update []
  (let [{:mode mode} (vim.api.nvim_get_mode)]
    (when (= mode "n")
      (fn format-message [msg]
        (var prefix "")
        (var suffix "")

        (when (not= msg.title "")
          (set prefix (string.format "%s: " msg.title)))

        (when (not= msg.name "")
          (set prefix (string.format "[%s] %s" msg.name prefix)))

        (when msg.percentage
          (set suffix (string.format " (%s)" msg.percentage)))

        (string.format "%s%s%s" prefix msg.message suffix))

      (let [messages (vim.lsp.util.get_progress_messages)]
        (each [_ message (ipairs messages)]
          (debounced-notify.call (format-message message)))))))

(fn on-attach []
  (helpers.augroup "fsouza__lsp_progress" [{:events ["User LspProgressUpdate"]
                                            :command (helpers.fn-cmd on-progress-update)}]))

{:on-attach (helpers.once on-attach)}
