(import-macros {: if-nil : abuf} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(fn run [bufname]
  (let [dir (vim.fn.fnamemodify bufname ":h")]
    (vim.fn.mkdir dir :p))
  nil)

(fn register-for-buffer [bufnr]
  (let [event-buffer (abuf)
        bufnr (if-nil bufnr event-buffer 0)
        bufname (vim.api.nvim_buf_get_name bufnr)]
    (when (not= "" bufname)
      (helpers.augroup (.. :fsouza__mkdir_ bufnr)
                       [{:events [:BufWritePre]
                         :targets [(string.format "<buffer=%d>" bufnr)]
                         :once true
                         :callback #(run bufname)}])))
  nil)

(fn setup []
  (helpers.augroup :fsouza__mkdir
                   [{:events [:BufNew]
                     :targets ["*"]
                     :callback register-for-buffer}])
  (register-for-buffer (vim.api.nvim_get_current_buf)))

{: setup}
