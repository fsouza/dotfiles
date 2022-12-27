(import-macros {: vim-schedule : mod-invoke} :helpers)

(fn set-from-env-var [cb]
  (cb (os.getenv :VIRTUAL_ENV)))

(fn set-from-cmd [exec args cb]
  (mod-invoke :fsouza.lib.cmd :run exec {: args} nil
              #(if (= $1.exit-status 0)
                   (cb (vim.trim $1.stdout))
                   (cb nil))))

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
  (let [path (require :fsouza.pl.path)
        folders [:venv :.venv]]
    (fn test-folder [idx]
      (let [folder (. folders idx)]
        (if folder
            (let [venv-candidate (path.join (vim.loop.cwd) folder)]
              (path.async-which (path.join venv-candidate :bin :python3)
                                #(if (not= $1 "")
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
  (let [path (require :fsouza.pl.path)]
    (detect-virtualenv (fn [virtualenv]
                         (if virtualenv
                             (do
                               (vim-schedule (tset vim.env :VIRTUAL_ENV
                                                   virtualenv))
                               (cb (path.join virtualenv :bin :python3)))
                             (cb nil))))))

{: detect-interpreter}
