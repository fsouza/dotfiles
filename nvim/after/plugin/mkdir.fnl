(fn run [bufname]
  (let [dir (vim.fs.dirname bufname)]
    (vim.fn.mkdir dir :p)))

(fn register-for-buffer [bufnr]
  (let [bufname (vim.api.nvim_buf_get_name bufnr)
        {: augroup} (require :fsouza.lib.nvim-helpers)]
    (when (and (not= "" bufname) (= (string.find bufname "^%a+://") nil))
      (augroup (.. :fsouza__mkdir_ bufnr)
               [{:events [:BufWritePre]
                 :targets [(string.format "<buffer=%d>" bufnr)]
                 :once true
                 :callback #(run bufname)}]))))

(let [{: augroup} (require :fsouza.lib.nvim-helpers)]
  (augroup :fsouza__mkdir
           [{:events [:BufNew]
             :targets ["*"]
             :callback #(register-for-buffer $1.buf)}])
  (each [_ bufnr (ipairs (vim.api.nvim_list_bufs))]
    (register-for-buffer bufnr)))
