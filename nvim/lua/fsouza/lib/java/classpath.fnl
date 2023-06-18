(import-macros {: mod-invoke} :helpers)

(local cache {})

(macro find-gradlew []
  `(. (vim.fs.find [:gradlew] {:upward true :type :file}) 1))

(lambda get-cp-from-gradle [gradlew cb]
  (fn on-finished [result]
    (if (not= result.exit-status 0)
        (cb [])
        (let [prefix "cp-entry "
              lines (-> result.stdout
                        (vim.split "\n" {:plain true :trimempty true}))]
          (->> lines
               (mod-invoke :fsouza.pl.tablex :filter-map
                           #(if (vim.startswith $1 prefix)
                                (string.sub $1 (+ (length prefix) 1))
                                nil))
               (cb)))))

  (let [path (require :fsouza.pl.path)
        cwd (path.dirname gradlew)]
    ;; TODO: don't hardcode -Xmx
    (mod-invoke :fsouza.lib.cmd :run gradlew
                {:args [:-Porg.gradle.jvmargs=-Xmx8192M
                        :-I
                        (path.join _G.dotfiles-dir :nvim :etc
                                   :projectClassPathFinder.gradle)
                        :nvimProjectDeps
                        :--quiet]
                 : cwd} on-finished)))

;; TODO: this can take some time, we need some progress reporting. I wanna use
;; fidget.nvim for this, but that would require the new API.
(lambda gradle-classpath-items [cb ?no-cache]
  (let [gradlew (find-gradlew)]
    (if gradlew
        (let [cached-result (. cache gradlew)]
          (if (and (not ?no-cache) cached-result)
              (cb cached-result)
              (get-cp-from-gradle gradlew
                                  #(do
                                     (tset cache gradlew $1)
                                     (cb $1)))))
        (cb nil))))

{: gradle-classpath-items}
