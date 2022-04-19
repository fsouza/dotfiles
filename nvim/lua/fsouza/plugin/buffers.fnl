;; This is a simple plugin that keeps track of all filepaths open in neovim.
;; The idea is to make that information available in libuv callbacks (can't
;; call vim.api.nvim_list_bufs from a luv callback).

(import-macros {: if-nil : mod-invoke : abuf} :helpers)

(local files {})

(fn set-from-bufnr [bufnr v]
  (let [bufname (vim.api.nvim_buf_get_name bufnr)]
    (when (not= bufname "")
      (let [path (require :fsouza.pl.path)
            filepath (path.abspath bufname)]
        (tset files filepath v)))))

(fn set-abuf [v]
  (let [bufnr (abuf)]
    (when bufnr
      (set-from-bufnr bufnr v))))

(fn has-file [filepath]
  (. files filepath))

(fn setup-augroup []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__buffers
              [{:events [:BufNewFile :BufReadPost]
                :targets ["*"]
                :callback #(set-abuf true)}
               {:events [:BufDelete] :targets ["*"] :callback #(set-abuf nil)}]))

(fn register-current-buffers []
  (let [bufs (vim.api.nvim_list_bufs)]
    (each [_ bufnr (ipairs bufs)]
      (set-from-bufnr bufnr true))))

(fn setup []
  (setup-augroup)
  (register-current-buffers))

{: setup : has-file}
