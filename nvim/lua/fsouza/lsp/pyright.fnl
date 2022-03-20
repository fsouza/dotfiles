(import-macros {: vim-schedule} :helpers)

(fn set-from-env-var [cb]
  (cb (os.getenv :VIRTUAL_ENV)))

(fn set-from-cmd [exec args cb]
  (let [cmd (require :fsouza.lib.cmd)]
    (cmd.run exec {: args} nil #(if (= $1.exit-status 0)
                                    (cb (vim.trim $1.stdout))
                                    (cb nil)))))

(fn set-from-poetry [cb]
  (vim.loop.fs_stat :poetry.lock
                    #(if $1
                         (cb nil)
                         (set-from-cmd :poetry [:env :info :-p] cb))))

(fn set-from-pipenv [cb]
  (vim.loop.fs_stat :Pipfile.lock
                    #(if $1
                         (cb nil)
                         (set-from-cmd :pipenv [:--venv] cb))))

(fn set-from-venv-folder [cb]
  (let [path (require :pl.path)
        folders [:venv :.venv]]
    (fn test-folder [idx]
      (let [folder (. folders idx)]
        (if folder
            (let [venv-candidate (path.join (vim.loop.cwd) folder)]
              (vim.loop.fs_stat (path.join venv-candidate :bin :python)
                                #(if (and (not $1) (= $2.type :file))
                                     (cb venv-candidate)
                                     (test-folder (+ idx 1)))))
            (cb nil))))

    (test-folder 1)))

(fn detect-virtualenv [cb]
  (let [detectors [set-from-venv-folder
                   set-from-env-var
                   set-from-poetry
                   set-from-pipenv]]
    (fn detect [idx]
      (let [detector (. detectors idx)]
        (when detector
          (detector #(if $1
                         (cb $1)
                         (detect (+ idx 1)))))))

    (detect 1)))

(fn detect-python-interpreter [cb]
  (let [path (require :pl.path)]
    (detect-virtualenv (fn [virtualenv]
                         (when virtualenv
                           (vim-schedule (tset vim.env :VIRTUAL_ENV virtualenv))
                           (cb (path.join virtualenv :bin :python)))))))

(fn detect-pythonPath [client]
  (let [cache-dir (vim.fn.stdpath :cache)]
    (detect-python-interpreter (fn [python-path]
                                 (when python-path
                                   (tset client.config.settings.python
                                         :pythonPath python-path)
                                   (client.notify :workspace/didChangeConfiguration
                                                  {:settings client.config.settings}))))))

{: detect-pythonPath}
