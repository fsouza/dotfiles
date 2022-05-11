(import-macros {: if-nil : mod-invoke} :helpers)

;; maps number to a terminal, where a terminal is a table with the following
;; shape: { bufnr: ..., job-id: ... }
(local terminals {})

(fn create-terminal [term-id]
  (let [filetype :fsouza-terminal
        bufnr (vim.api.nvim_create_buf true false)]
    (vim.api.nvim_buf_set_option bufnr :filetype filetype)
    (vim.api.nvim_buf_call bufnr
                           #(let [job-id (vim.fn.termopen (string.format "%s;#fsouza_term;%s"
                                                                         vim.o.shell
                                                                         term-id)
                                                          {:detach false
                                                           :on_exit #(tset terminals
                                                                           term-id
                                                                           nil)})]
                              (tset terminals term-id {: bufnr : job-id}))))
  (. terminals term-id))

(fn get-term [term-id]
  (let [term (. terminals term-id)]
    (if (and term (vim.api.nvim_buf_is_valid term.bufnr))
        term
        (do
          (tset terminals term-id nil)
          nil))))

(fn ensure-term [term-id]
  (let [term (get-term term-id)]
    (if term
        term
        (create-terminal term-id))))

(fn open [term-id]
  (let [{: bufnr} (ensure-term term-id)]
    (vim.api.nvim_set_current_buf bufnr)))

(fn run [term-id cmd]
  (let [{: job-id} (ensure-term term-id)]
    (vim.fn.chansend job-id [cmd ""])))

(fn cr []
  (let [cfile (vim.fn.expand :<cfile>)]
    (when (= (vim.fn.filereadable cfile) 1)
      (vim.api.nvim_cmd {:cmd :only :mods {:silent true}} {})
      (vim.api.nvim_cmd {:cmd :wincmd :args [:F]} {}))))

(fn v-cr []
  (when (mod-invoke :fsouza.lib.qf :set-from-visual-selection)
    (vim.api.nvim_cmd {:cmd :only :mods {:silent true}} {})
    (vim.api.nvim_cmd {:cmd :cfirst} {})
    (vim.api.nvim_cmd {:cmd :copen} {})
    (vim.api.nvim_cmd {:cmd :wincmd :args [:p]} {})))

{: open : cr : run : v-cr}
