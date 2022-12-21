(import-macros {: if-nil : mod-invoke : vim-schedule} :helpers)
(import-macros {: get-cache-cmd : find-venv-bin : if-bin} :lsp-helpers)

(fn get-python-tools [cb]
  (let [path (require :fsouza.pl.path)
        py3 (find-venv-bin :python3)
        gen-python-tools (path.join config-dir :langservers :bin
                                    :gen-efm-python-tools.py)]
    (fn on-finished [result]
      (if (not= result.exit-status 0)
          (error result.stderr)
          (->> result.stdout
               (vim.fn.json_decode)
               (cb))))

    (mod-invoke :fsouza.lib.cmd :run py3 {:args [gen-python-tools]} nil
                on-finished)))

{: get-python-tools}
