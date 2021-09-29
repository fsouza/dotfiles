(local helpers (require "fsouza.lib.nvim_helpers"))

(fn run [bufname]
  (let [dir (vim.fn.fnamemodify bufname ":h")]
    (vim.fn.mkdir dir "p")))

(fn register-for-buffer [bufnr]
  (let [bufnr (helpers.if-nil bufnr (partial vim.fn.expand "<abuf>"))
        bufname (vim.api.nvim_buf_get_name bufnr)]
    (when (not= "" bufname)
      (helpers.augroup (.. "fsouza__mkdir_" bufnr) [{:events ["BufWritePre"]
                                                     :targets [(string.format "<buffer=%d>" bufnr)]
                                                     :modifiers ["++once"]
                                                     :command (helpers.fn-cmd (partial run bufname))}]))))

(fn setup []
  (helpers.augroup "fsouza__mkdir" [{:events ["BufNew"]
                                     :targets ["*"]
                                     :command (helpers.fn-cmd register-for-buffer)}])
  (register-for-buffer (vim.api.nvim_get_current_buf)))

{:setup setup}
