;; this module exists for efm tools that are shared across different file
;; types, such as prettierd and eslintd.

(import-macros {: if-bin} :lsp-helpers)

(fn get-shfmt [cb]
  (let [path (require :fsouza.pl.path)
        shfmt-path (path.join cache-dir :langservers :bin :shfmt)]
    (cb {:formatCommand (string.format "%s -" shfmt-path) :formatStdin true})))

(fn get-node-bin [bin-name cb]
  (let [path (require :fsouza.pl.path)
        local-bin (path.join :node_modules :.bin bin-name)
        default-bin (path.join config-dir :langservers :node_modules :.bin
                               bin-name)]
    (if-bin local-bin default-bin cb)))

(fn get-prettierd [cb]
  (get-node-bin :prettierd
                #(cb {:formatCommand (string.format "%s ${INPUT}" $1)
                      :formatStdin true
                      :env [(.. :XDG_RUNTIME_DIR= cache-dir)]})))

(fn get-eslintd [cb]
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
                         :env [(.. :XDG_RUNTIME_DIR=cache-dir)]}
                        {:lintCommand (string.format "%s --stdin --stdin-filename ${INPUT} --format unix"
                                                     $1)
                         :lintStdin true
                         :lintSource :eslint
                         :lintIgnoreExitCode true
                         :lintFormats ["%f:%l:%c: %m"]
                         :rootMarkers root-markers
                         :requireMarker true}]))))

{: get-shfmt : get-eslintd : get-prettierd}
