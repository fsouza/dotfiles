(import-macros {: if-nil : mod-invoke : vim-schedule} :helpers)
(import-macros {: get-cache-cmd : find-venv-bin : if-bin} :lsp-helpers)

(macro quote-arg [arg]
  `(string.format "\"%s\"" ,arg))

(fn process-args [args]
  (let [args (if-nil args [])]
    (accumulate [acc "" _ arg (ipairs args)]
      (.. acc " " (quote-arg arg)))))

(fn get-python-bin [bin-name cb]
  (let [path (require :fsouza.pl.path)
        virtualenv (os.getenv :VIRTUAL_ENV)
        default-bin (find-venv-bin bin-name)]
    (if virtualenv
        (let [venv-bin-name (path.join virtualenv :bin bin-name)]
          (if-bin venv-bin-name default-bin cb))
        (cb default-bin))))

(fn get-black [args cb]
  (get-python-bin :black
                  #(cb {:formatCommand (string.format "%s --fast --quiet %s -"
                                                      $1 (process-args args))
                        :formatStdin true
                        :rootMarkers [:.git ""]})))

(fn get-isort [args cb]
  (get-python-bin :isort
                  #(cb {:formatCommand (string.format "%s %s -" $1
                                                      (process-args args))
                        :formatStdin true
                        :rootMarkers [:.isort.cfg :.git ""]})))

(fn get-autoflake [_ cb]
  (get-python-bin :autoflake
                  #(cb {:formatCommand (string.format "%s --expand-star-imports --remove-all-unused-imports -"
                                                      $1)
                        :formatStdin true})))

(fn get-ruff-fix [_ cb]
  (let [path (require :fsouza.pl.path)]
    (cb {:formatCommand (->> :ruff (find-venv-bin)
                             (string.format "%s --silent --exit-zero --fix -"))
         :formatStdin true
         :rootMarkers [:.git ""]})))

(fn get-flake8 [args cb]
  (get-python-bin :flake8 #(cb {:lintCommand (string.format "%s --stdin-display-name ${INPUT} --format \"%%(path)s:%%(row)d:%%(col)d: %%(code)s %%(text)s\" %s -"
                                                            $1
                                                            (process-args args))
                                :lintStdin true
                                :lintSource :flake8
                                :lintFormats ["%f:%l:%c: %m"]
                                :lintIgnoreExitCode true
                                :rootMarkers [:.flake8 :.git ""]}
                               get-autoflake)))

(fn get-ruff [args cb]
  (let [path (require :fsouza.pl.path)]
    (cb {:lintCommand (->> :ruff (find-venv-bin)
                           (string.format "%s --stdin-filename ${INPUT} -"))
         :lintStdin true
         :lintSource :ruff
         :lintFormats ["%f:%l:%c: %m"]
         :lintIgnoreExitCode true
         :rootMarkers [:.git ""]} get-ruff-fix)))

(fn get-add-trailing-comma [args cb]
  (get-python-bin :add-trailing-comma
                  #(cb {:formatCommand (string.format "%s --exit-zero-even-if-changed %s -"
                                                      $1 (process-args args))
                        :formatStdin true})))

(fn get-reorder-python-imports [args cb]
  (get-python-bin :reorder-python-imports
                  #(cb {:formatCommand (string.format "%s --exit-zero-even-if-changed %s -"
                                                      $1 (process-args args))
                        :formatStdin true})))

(fn get-autopep8 [args cb]
  (get-python-bin :autopep8
                  #(cb {:formatCommand (string.format "%s %s -" $1
                                                      (process-args args))
                        :formatStdin true})))

(fn get-pyupgrade [args cb]
  (get-python-bin :pyupgrade
                  #(cb {:formatCommand (string.format "%s --exit-zero-even-if-changed %s -"
                                                      $1 (process-args args))
                        :formatStdin true})))

(fn try-read-precommit-config [file-path cb]
  (let [empty-result {:repos []}]
    (vim.loop.fs_open file-path :r (tonumber :644 8)
                      (fn [err fd]
                        (if err
                            (cb nil)
                            (let [block-size 1024]
                              (var offset 0)
                              (var content "")

                              (fn on-read [err chunk]
                                (if err
                                    (cb empty-result)
                                    (if (= (length chunk) 0)
                                        (do
                                          (vim.loop.fs_close fd)
                                          (cb (mod-invoke :lyaml :load content)))
                                        (do
                                          (set content (.. content chunk))
                                          (set offset (+ offset block-size))
                                          (vim.loop.fs_read fd block-size
                                                            offset on-read)))))

                              (vim.loop.fs_read fd block-size offset on-read)))))))

(fn get-python-tools [cb]
  (let [fns [{:fn get-flake8}
             {:fn get-black}
             {:fn get-add-trailing-comma}
             {:fn get-reorder-python-imports}
             {:fn get-autoflake}]
        pre-commit-config-file-path :.pre-commit-config.yaml]
    (try-read-precommit-config pre-commit-config-file-path
                               (fn [pre-commit-config]
                                 (let [pc-repo-tools {"https://github.com/pycqa/flake8" get-flake8
                                                      "https://github.com/pycqa/autoflake" get-autoflake
                                                      "https://github.com/myint/autoflake" get-autoflake
                                                      "https://github.com/psf/black" get-black
                                                      "https://github.com/ambv/black" get-black
                                                      "https://github.com/asottile/add-trailing-comma" get-add-trailing-comma
                                                      "https://github.com/asottile/reorder_python_imports" get-reorder-python-imports
                                                      "https://github.com/asottile/pyupgrade" get-pyupgrade
                                                      "https://github.com/pre-commit/mirrors-autopep8" get-autopep8
                                                      "https://github.com/pre-commit/mirrors-isort" get-isort
                                                      "https://github.com/pycqa/isort" get-isort
                                                      "https://github.com/timothycrosley/isort" get-isort
                                                      "https://github.com/charliermarsh/ruff-pre-commit" get-ruff}
                                       find-repo (fn [repo]
                                                   (let [repo-url (string.lower repo.repo)
                                                         args (if-nil (?. repo
                                                                          :hooks
                                                                          1
                                                                          :args)
                                                                      [])
                                                         f (. pc-repo-tools
                                                              repo-url)]
                                                     (if f {:fn f : args} nil)))
                                       pre-commit-fns (if pre-commit-config
                                                          (mod-invoke :fsouza.pl.tablex
                                                                      :filter-map
                                                                      find-repo
                                                                      pre-commit-config.repos)
                                                          nil)]
                                   (let [fns (if-nil pre-commit-fns fns)
                                         tools []
                                         timer (vim.loop.new_timer)]
                                     (var pending 0)

                                     (fn process-result [tool next-fn]
                                       (let [key (if tool.formatCommand
                                                     :formatCommand :lintCommand)
                                             cmd (. tool key)]
                                         (when (mod-invoke :fsouza.pl.tablex
                                                           :for-all tools
                                                           #(not= (. $1 key)
                                                                  cmd))
                                           (table.insert tools tool)))
                                       (if next-fn
                                           (next-fn nil process-result)
                                           (set pending (- pending 1))))

                                     (each [_ f (ipairs fns)]
                                       (set pending (+ pending 1))
                                       (f.fn f.args process-result))
                                     (timer:start 0 25
                                                  #(when (= pending 0)
                                                     (vim-schedule (cb tools))
                                                     (timer:close)))))))))

{: get-python-tools}
