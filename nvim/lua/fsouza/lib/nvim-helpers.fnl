(import-macros {: if-nil : cmd-map : vcmd-map} :helpers)

(fn register-cb [mod cb]
  (let [id (tostring cb)]
    (tset mod.fns id cb)
    id))

(fn create-mappings [mappings bufnr]
  (let [set-keymap-fn (if bufnr
                        (partial vim.api.nvim_buf_set_keymap bufnr)
                        vim.api.nvim_set_keymap)]
    (each [mode rules (pairs mappings)]
      (each [_ m (ipairs rules)]
        (set-keymap-fn mode m.lhs m.rhs (if-nil m.opts {}))))))

(fn remove-mappings [mappings bufnr]
  (let [del-keymap-fn (if bufnr
                        (partial vim.api.nvim_buf_del_key_map bufnr)
                        vim.api.nvim_del_keymap)]
    (each [mode rules (pairs mappings)]
      (each [_ m (ipairs rules)]
        (del-keymap-fn mode m.lhs)))))

(fn augroup [name commands]
  (vim.cmd (.. "augroup " name))
  (vim.cmd "autocmd!")
  (each [_ c (ipairs commands)]
    (vim.cmd (string.format
               "autocmd %s %s %s %s"
               (table.concat c.events ",")
               (table.concat (if-nil c.targets []) ",")
               (table.concat (if-nil c.modifiers []) " ")
               c.command)))
  (vim.cmd "augroup END"))

(fn once [f]
  (var result nil)
  (var called false)
  (fn [...]
    (when (not called)
      (set called true)
      (set result (f ...))
      result)
    result))

;; Provides a wrapper to a function that rewrites the current buffer, and does
;; a best effort to keep the buffer position.
(fn rewrite-wrap [f]
  (let [bufnr (vim.api.nvim_get_current_buf)
        cursor (vim.api.nvim_win_get_cursor 0)
        orig-lineno (. cursor 1)
        orig-colno (. cursor 2)
        orig-line (. (vim.api.nvim_buf_get_lines bufnr (- orig-lineno 1) orig-lineno true) 1)
        orig-nlines (vim.api.nvim_buf_line_count bufnr)
        view (vim.fn.winsaveview)]
    (f)

    (let [line-offset (- (vim.api.nvim_buf_line_count bufnr) orig-nlines)
          lineno (+ orig-lineno line-offset)
          new-line (. (vim.api.nvim_buf_get_lines bufnr (- lineno 1) lineno true) 1)
          col-offset (- (string.len (if-nil new-line "")) (string.len orig-line))]
      (tset view :lnum lineno)
      (tset view :col (+ orig-colno col-offset))
      (vim.fn.winrestview view))))

(let [mod {:fns []
           :create-mappings create-mappings
           :remove-mappings remove-mappings
           :augroup augroup
           :reset-augroup (fn [name] (augroup name []))
           :once once
           :rewrite-wrap rewrite-wrap}]
  (tset mod :fn-cmd (fn [f]
                      (let [id (register-cb mod f)]
                        (string.format "lua require('fsouza.lib.nvim-helpers').fns['%s']()" id))))
  (tset mod :fn-map (fn [f]
                      (cmd-map (mod.fn-cmd f))))
  (tset mod :vfn-map (fn [f]
                       (vcmd-map (mod.fn-cmd f))))
  (tset mod :ifn-map (fn [f]
                       (let [id (register-cb mod f)]
                         (string.format "<c-r>=luaeval(\"require('fsouza.lib.nvim-helpers').fns['%s']()\")<CR>" id))))
  mod)
