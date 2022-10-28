(import-macros {: mod-invoke} :helpers)

(macro config-log []
  `(let [level# (if vim.env.NVIM_DEBUG :trace :off)
         lsp-log# (require :vim.lsp.log)]
     (lsp-log#.set_level level#)
     (lsp-log#.set_format_func vim.inspect)))

(macro define-signs []
  (icollect [_ level (ipairs [:Error :Warn :Info :Hint])]
    (let [sign-name (.. :DiagnosticSign level)]
      `(vim.fn.sign_define ,sign-name {:text "" :numhl ,sign-name}))))

(fn setup []
  (define-signs)
  (config-log)
  (mod-invoke :fsouza.lsp.buf-diagnostic :register-filter :pyright
              #(mod-invoke :fsouza.lsp.servers.pyright :valid-diagnostic $1))
  (mod-invoke :fsouza.lsp.buf-diagnostic :register-filter :rust_analyzer
              #(mod-invoke :fsouza.lsp.servers.rust-analyzer :valid-diagnostic
                           $1))
  (mod-invoke :fsouza.lsp.servers.efm :setup))

{: setup}
