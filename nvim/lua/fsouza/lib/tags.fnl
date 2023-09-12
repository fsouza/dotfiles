(import-macros {: mod-invoke} :helpers)

(fn get-regex-from-command [command]
  (let [first (if (vim.startswith command "/") 2 1)
        last (if (vim.endswith command "/") -2 -1)]
    (-> command
        (string.sub first last)
        (vim.regex))))

;; note: this is done in a stupid way, but at least it's async :P
(fn serialize [tag]
  (let [regex (get-regex-from-command tag.cmd)
        filename (mod-invoke :fsouza.pl.path :relpath tag.filename)
        bufnr (vim.fn.bufadd filename)]
    (vim.fn.bufload bufnr)
    (let [seq (require :fsouza.pl.seq)
          s (-> bufnr
                (vim.api.nvim_buf_get_lines 0 -1 false)
                (seq.enum)
                (seq.filter #(regex:match_str $2)))
          (lnum text) (s)
          col (or (string.find text tag.name) 1)]
      (string.format "%s:%d:%d: %s" filename lnum col text))))

(fn jump-to-tag []
  (let [cword (vim.fn.expand :<cword>)
        expr (string.format "^%s$" cword)
        tags (vim.fn.taglist expr)]
    (if (= (length tags) 1)
        (vim.cmd.tag [cword])
        (do
          (fn fzf-items [fzf-cb]
            ((coroutine.wrap #(let [co (coroutine.running)]
                                (each [_ tag (ipairs tags)]
                                  (vim.schedule #(fzf-cb (serialize tag)
                                                         #(coroutine.resume co)))
                                  (coroutine.yield))
                                (fzf-cb)))))
          (mod-invoke :fsouza.lib.fuzzy :send-items fzf-items :Tags
                      {:use-lsp-actions true :enable-preview true})))))

{: jump-to-tag}
