(import-macros {: vim-schedule : if-nil} :helpers)

(local path (require :pl.path))
(local default-root-markers [".git"])
(local cache-dir (vim.fn.stdpath "cache"))
(local quote-arg (partial string.format "\"%s\""))

(fn process-args [args]
  (let [args (if-nil args [])]
    (accumulate [acc "" _ arg (ipairs args)]
      (.. acc " " (quote-arg arg)))))

(local find-venv-bin (partial path.join cache-dir "venv" "bin"))

(macro if-bin [bin-to-check fallback-bin cb]
  `(vim.loop.fs_stat ,bin-to-check (fn [err# stat#]
                                     (if (and (= err# nil) (= stat#.type "file"))
                                       (,cb ,bin-to-check)
                                       (,cb ,fallback-bin)))))

(fn get-node-bin [bin-name cb]
  (let [local-bin (path.join "node_modules" ".bin" bin-name)
        default-bin (path.join config-dir "langservers" "node_modules" ".bin" bin-name)]
    (if-bin local-bin default-bin cb)))

(fn get-python-bin [bin-name cb]
  (let [virtualenv (os.getenv "VIRTUAL_ENV")
        default-bin (find-venv-bin bin-name)]
    (if virtualenv
      (let [venv-bin-name (path.join virtualenv "bin" bin-name)]
        (if-bin venv-bin-name default-bin cb))
      (cb default-bin))))

(fn get-black [args cb]
  (get-python-bin
    "black"
    #(cb {:formatCommand (string.format "%s --fast --quiet %s -" $1 (process-args args))
          :formatStdin true
          :rootMarkers [".git" ""]})))

(fn get-isort [args cb]
  (get-python-bin
    "isort"
    #(cb {:formatCommand (string.format "%s %s -" $1 (process-args args))
          :formatStdin true
          :rootMarkers [".isort.cfg" ".git" ""]})))

(fn get-autoflake8 [_ cb]
  (get-python-bin
    "autoflake8"
    #(cb {:formatCommand (string.format "%s --expand-star-imports --exit-zero-even-if-changed -" $1)
          :formatStdin true
          :rootMarkers default-root-markers})))

(fn get-flake8 [args cb]
  (get-python-bin
    "flake8"
    #(cb {:lintCommand (string.format "%s --stdin-display-name ${INPUT} --format \"%%(path)s:%%(row)d:%%(col)d: %%(code)s %%(text)s\" %s -" $1 (process-args args))
          :lintStdin true
          :lintSource "flake8"
          :lintFormats ["%f:%l:%c: %m"]
          :rootMarkers [".flake8" ".git" ""]} get-autoflake8)))

(fn get-add-trailing-comma [args cb]
  (get-python-bin
    "add-trailing-comma"
    #(cb {:formatCommand (string.format "%s --exit-zero-even-if-changed %s -" $1 (process-args args))
          :formatStdin true
          :rootMarkers default-root-markers})))

(fn get-reorder-python-imports [args cb]
  (get-python-bin
    "reorder-python-imports"
    #(cb {:formatCommand (string.format "%s --exit-zero-even-if-changed %s -" $1 (process-args args))
          :formatStdin true
          :rootMarkers default-root-markers})))

(fn get-autopep8 [args cb]
  (get-python-bin
    "autopep8"
    #(cb {:formatCommand (string.format "%s %s -" $1 (process-args args))
          :formatStdin true
          :rootMarkers default-root-markers})))

(fn get-buildifier [cb]
  (let [buildifierw (path.join config-dir "langservers" "bin" "buildifierw.py")
        py3 (find-venv-bin "python3")]
    (cb {:formatCommand (string.format "%s %s ${INPUT}" py3 buildifierw)
         :formatStdin true
         :rootMarkers default-root-markers
         :env [(.. "NVIM_CACHE_DIR=" cache-dir)]})))

(fn get-dune [cb]
  (cb {:formatCommand "dune format-dune-file"
       :formatStdin true
       :rootMarkers default-root-markers}))

(fn get-ocamlformat [cb]
  (cb {:formatCommand "ocamlformat --name ${INPUT} -"
       :formatStdin true
       :rootMarkers [".ocamlformat"]}))

(fn get-shellcheck [cb]
  (cb {:lintCommand "shellcheck -f gcc -x -"
       :lintStdin true
       :lintSource "shellcheck"
       :lintFormats ["%f:%l:%c: %trror: %m" "%f:%l:%c: %tarning: %m" "%f:%l:%c: %tote: %m"]
       :rootMarkers default-root-markers}))

(fn get-shfmt [cb]
  (let [shfmt-path (path.join cache-dir "langservers" "bin" "shfmt")]
    (cb {:formatCommand (string.format "%s -" shfmt-path)
         :formatStdin true
         :rootMarkers default-root-markers})))

(fn get-prettierd [cb]
  (get-node-bin
    "prettierd"
    #(cb {:formatCommand (string.format "%s ${INPUT}" $1)
          :formatStdin true
          :env [(.. "XDG_RUNTIME_DIR=" cache-dir)]})))

(fn get-eslintd-config [cb]
  (get-node-bin
    "eslint_d"
    (fn [eslint_d-path]
      (let [eslint-config-files [".eslintrc.js"
                                 ".eslintrc.cjs"
                                 ".eslintrc.yaml"
                                 ".eslintrc.yml"
                                 ".eslintrc.json"]]
        (fn check-eslint-config [idx]
          (let [config-file (. eslint-config-files idx)]
            (if (not config-file)
              (cb [])
              (vim.loop.fs_stat config-file (fn [err stat]
                                              (if (and (= err nil) (= stat.type "file"))
                                                (cb [{:formatCommand (string.format "%s --stdin --stdin-filename ${INPUT} --fix-to-stdout" eslint_d-path)
                                                      :formatStdin true
                                                      :env [(.. "XDG_RUNTIME_DIR=" cache-dir)]}
                                                     {:lintCommand (string.format "%s --stdin --stdin-filename ${INPUT} --format unix" eslint_d-path)
                                                      :lintStdin true
                                                      :lintSource "eslint"
                                                      :rootMarkers [".eslintrc.js"
                                                                    ".eslintrc.cjs"
                                                                    ".eslintrc.yaml"
                                                                    ".eslintrc.yml"
                                                                    ".eslintrc.json"
                                                                    ".git"
                                                                    "package.json"]}])
                                                (check-eslint-config (+ idx 1))))))))
        (check-eslint-config 1)))))

(fn try-read-precommit-config [file-path cb]
  (let [empty-result {:repos []}
        lyaml (require :lyaml)]

    (vim.loop.fs_open
      file-path
      "r"
      (tonumber "644" 8)
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
                    (cb (lyaml.load content)))
                  (do
                    (set content (.. content chunk))
                    (set offset (+ offset block-size))
                    (vim.loop.fs_read fd block-size offset on-read)))))

            (vim.loop.fs_read fd block-size offset on-read)))))))

(fn get-python-tools [cb]
  (let [fns [{:fn get-flake8}
             {:fn get-black}
             {:fn get-add-trailing-comma}
             {:fn get-reorder-python-imports}
             {:fn get-autoflake8}]
        pre-commit-config-file-path ".pre-commit-config.yaml"]
    (try-read-precommit-config
      pre-commit-config-file-path
      (fn [pre-commit-config]
        (let [pc-repo-tools {"https://github.com/pycqa/flake8" get-flake8
                             "https://github.com/psf/black" get-black
                             "https://github.com/ambv/black" get-black
                             "https://github.com/asottile/add-trailing-comma" get-add-trailing-comma
                             "https://github.com/asottile/reorder_python_imports" get-reorder-python-imports
                             "https://github.com/pre-commit/mirrors-autopep8" get-autopep8
                             "https://github.com/pre-commit/mirrors-isort" get-isort
                             "https://github.com/fsouza/autoflake8" get-autoflake8}
              tablex (require :fsouza.tablex)
              find-repo (fn [repo]
                          (let [repo-url repo.repo
                                args (if-nil (?. repo :hooks 1 :args) [])
                                f (. pc-repo-tools repo-url)]
                            (if f
                              {:fn f
                               :args args}
                              nil)))
              pre-commit-fns (if pre-commit-config
                               (tablex.filter-map find-repo pre-commit-config.repos)
                               nil)]

          (let [fns (if-nil pre-commit-fns fns)
                tools []
                timer (vim.loop.new_timer)]
            (var pending 0)

            (fn process-result [tool next-fn]
              (table.insert tools tool)
              (if next-fn
                (next-fn nil process-result)
                (set pending (- pending 1))))

            (each [_ f (ipairs fns)]
              (set pending (+ pending 1))
              (f.fn f.args process-result))

            (timer:start 0 25 #(when (= pending 0)
                                 (vim-schedule (cb tools))
                                 (timer:close)))))))))

(local prettierd-fts ["changelog" "css" "graphql" "html" "javascript" "json"
                      "typescript" "typescriptreact" "yaml"])

(fn get-filetypes []
  (vim.tbl_flatten ["bzl" "dune" "ocaml" "python" "sh" prettierd-fts]))

(fn basic-settings []
  (values {:lintDebounce 250000000
           :rootMarkers default-root-markers
           :languages (vim.empty_dict)}
          (get-filetypes)))

(fn get-settings [cb]
  (let [settings (basic-settings)]
    (tset settings :languages {})

    (fn add-if-not-empty [language tool]
      (when (or tool.formatCommand tool.lintCommand)
        (let [tools (if-nil (?. settings :languages language) [])]
          (table.insert tools tool)
          (tset settings.languages language tools))))

    (var pending 0)
    (fn pending-wrapper [f original-cb]
      (set pending (+ pending 1))

      (f (fn [...]
           (original-cb ...)
           (set pending (- pending 1)))))

    (let [simple-tool-factories [{:language "sh"
                                  :fn get-shellcheck}
                                 {:language "sh"
                                  :fn get-shfmt}
                                 {:language "dune"
                                  :fn get-dune}
                                 {:language "ocaml"
                                  :fn get-ocamlformat}
                                 {:language "bzl"
                                  :fn get-buildifier}]
          timer (vim.loop.new_timer)]
      (each [_ f (ipairs simple-tool-factories)]
        (let [{:fn f : language} f]
          (pending-wrapper f #(add-if-not-empty language $1))))

      (pending-wrapper get-eslintd-config #(let [eslint-fts ["javascript" "typescript"]]
                                             (each [_ eslint (ipairs $1)]
                                               (each [_ ft (ipairs eslint-fts)]
                                                 (add-if-not-empty ft eslint)))))

      (pending-wrapper get-prettierd #(each [_ ft (ipairs prettierd-fts)]
                                        (add-if-not-empty ft $1)))

      (pending-wrapper get-python-tools #(tset settings.languages :python $1))

      (timer:start 0 25 #(when (= pending 0)
                           (vim-schedule (cb settings))
                           (timer:close))))))

(fn gen-config [client]
  (get-settings (fn [settings]
                  (tset client.config :settings settings)
                  (client.notify "workspace/didChangeConfiguration" {:settings client.config.settings}))))

{: basic-settings
 : gen-config}
