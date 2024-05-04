;; this module exists for efm tools that are shared across different file
;; types, such as prettierd and eslintd.

(import-macros {: mod-invoke} :helpers)

(fn get-node-bin [bin-name cb]
  (let [local-bin (vim.fs.joinpath :node_modules :.bin bin-name)
        default-bin (string.format "fnm exec --using %s -- %s"
                                   (vim.fs.joinpath _G.config-dir :langservers
                                                    :.node-version)
                                   (vim.fs.joinpath _G.config-dir :langservers
                                                    :node_modules :.bin bin-name))]
    (vim.uv.fs_stat local-bin
                    (fn [err# stat#]
                      (if (and (= err# nil) (= stat#.type :file))
                          (cb local-bin)
                          (cb default-bin))))))

(fn with-runtime-dir [tool cb]
  (let [xdg-runtime-dir (vim.fs.joinpath _G.cache-dir :prettierd)]
    (mod-invoke :fsouza.lib.path :mkdir xdg-runtime-dir true
                #(cb xdg-runtime-dir))))

(fn get-prettierd [cb]
  (with-runtime-dir :prettierd
    #(let [xdg-runtime-dir $1]
       (mod-invoke :fsouza.lib.path :mkdir xdg-runtime-dir true
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
                              :env [(.. :XDG_RUNTIME_DIR= xdg-runtime-dir)]}
                             {:lintCommand (string.format "%s --stdin --stdin-filename ${INPUT} --format unix"
                                                          $1)
                              :lintStdin true
                              :lintSource :eslint
                              :lintIgnoreExitCode true
                              :lintFormats ["%f:%l:%c: %m"]
                              :lintAfterOpen true
                              :rootMarkers root-markers
                              :requireMarker true
                              :env [(.. :XDG_RUNTIME_DIR= xdg-runtime-dir)]}]))))))

{: get-eslintd : get-prettierd}
