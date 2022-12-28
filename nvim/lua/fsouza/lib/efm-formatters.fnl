;; this module exists for efm tools that are shared across different file
;; types, such as prettierd and eslintd.

(import-macros {: mod-invoke} :helpers)

(fn get-shfmt [cb]
  (let [path (require :fsouza.pl.path)
        shfmt-path (path.join cache-dir :langservers :bin :shfmt)]
    (cb {:formatCommand (string.format "%s -" shfmt-path) :formatStdin true})))

(fn get-node-bin [bin-name cb]
  (let [path (require :fsouza.pl.path)
        local-bin (path.join :node_modules :.bin bin-name)
        default-bin (path.join config-dir :langservers :node_modules :.bin
                               bin-name)]
    (vim.loop.fs_stat local-bin
                      (fn [err# stat#]
                        (if (and (= err# nil) (= stat#.type :file))
                            (cb local-bin)
                            (cb default-bin))))))

(fn with-runtime-dir [tool cb]
  (let [path (require :fsouza.pl.path)
        xdg-runtime-dir (path.join cache-dir :prettierd)]
    (path.async-mkdir xdg-runtime-dir 493 true #(cb xdg-runtime-dir))))

(fn get-prettierd [cb]
  (with-runtime-dir :prettierd
                    #(let [xdg-runtime-dir $1]
                       (mod-invoke :fsouza.pl.path :async-mkdir xdg-runtime-dir
                                   493 true
                                   #(get-node-bin :prettierd
                                                  #(cb {:formatCommand (string.format "%s ${INPUT}"
                                                                                      $1)
                                                        :formatStdin true
                                                        :env [(.. :XDG_RUNTIME_DIR=
                                                                  xdg-runtime-dir)]}))))))

(fn get-eslintd [cb]
  (with-runtime-dir :eslintd
                    #(let [xdg-runtime-dir $1]
                       (get-node-bin :eslint_d
                                     #(let [root-markers [:.eslintrc.js
                                                          :.eslintrc.cjs
                                                          :.eslintrc.yaml
                                                          :.eslintrc.yml
                                                          :.eslintrc.json]]
                                        (cb [{:formatCommand (string.format "%s --stdin --stdin-filename ${INPUT} --fix-to-stdout"
                                                                            $1)
                                              :formatStdin true
                                              :rootMarkers root-markers
                                              :requireMarker true
                                              :env [(.. :XDG_RUNTIME_DIR=
                                                        xdg-runtime-dir)]}
                                             {:lintCommand (string.format "%s --stdin --stdin-filename ${INPUT} --format unix"
                                                                          $1)
                                              :lintStdin true
                                              :lintSource :eslint
                                              :lintIgnoreExitCode true
                                              :lintFormats ["%f:%l:%c: %m"]
                                              :rootMarkers root-markers
                                              :requireMarker true
                                              :env [(.. :XDG_RUNTIME_DIR=
                                                        xdg-runtime-dir)]}]))))))

{: get-shfmt : get-eslintd : get-prettierd}
