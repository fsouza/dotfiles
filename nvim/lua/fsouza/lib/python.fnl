(fn set-from-env-var [cb]
  (cb (or (os.getenv :VIRTUAL_ENV) (os.getenv :CONDA_PREFIX))))

(fn set-from-cmd [exec args cb]
  (let [cmd (require :fsouza.lib.cmd)]
    (cmd.run exec {: args} #(if (= $1.exit-status 0)
                                (cb (vim.trim $1.stdout))
                                (cb nil)))))

(fn set-from-poetry [cb]
  (vim.uv.fs_stat :poetry.lock
                  #(if $1
                       (cb nil)
                       (set-from-cmd :poetry [:env :info :-p] cb))))

(fn set-from-pipenv [cb]
  (vim.uv.fs_stat :Pipfile.lock
                  #(if $1
                       (cb nil)
                       (set-from-cmd :pipenv [:--venv] cb))))

(fn set-from-venv-folder [cb]
  (let [path (require :fsouza.lib.path)
        folders [:venv :.venv]]
    (fn test-folder [idx]
      (let [folder (. folders idx)]
        (if folder
            (let [venv-candidate (vim.fs.joinpath (vim.uv.cwd) folder)
                  interpreter-candidate (vim.fs.joinpath venv-candidate :bin
                                                         :python3)]
              (vim.uv.fs_stat interpreter-candidate
                              #(if (and (= $1 nil) (= $2.type :file))
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
        (if detector
            (detector #(if $1
                           (cb $1)
                           (detect (+ idx 1))))
            (cb nil))))

    (detect 1)))

(lambda detect-interpreter [cb]
  (detect-virtualenv (fn [virtualenv]
                       (if virtualenv
                           (do
                             (vim.schedule #(tset vim.env :VIRTUAL_ENV
                                                  virtualenv))
                             (cb (vim.fs.joinpath virtualenv :bin :python3)))
                           (cb nil)))))

{: detect-interpreter}
