(import-macros {: if-nil} :helpers)

(fn handler [_ res ctx]
  (let [age 2000
        {: notify} (require :fsouza.lib.notif)
        {:client_id client-id} ctx
        client (vim.lsp.get_client_by_id client-id)
        client-name (if-nil client.name (string.format "client-%d" client-id))
        message (?. res :value :message)
        percentage (?. res :value :percentage)]
    (when message
      (let [p-msg (if (not= percentage nil)
                      ;; NB: need %%%%% because of feline.
                      (string.format " (%d%%%%)" percentage)
                      "")
            msg (string.format "[%s] %s%s" client-name message p-msg)]
        (notify {: msg : age})))))

(fn make-handler [debounce-ms]
  (let [{: debounce} (require :fsouza.lib.debounce)
        debounced-handler (debounce debounce-ms (vim.schedule_wrap handler))]
    (fn [...]
      (let [{: mode} (vim.api.nvim_get_mode)]
        (debounced-handler.call ...)))))

{:handler (make-handler 100)}
