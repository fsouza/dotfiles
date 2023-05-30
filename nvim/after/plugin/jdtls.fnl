(import-macros {: mod-invoke} :helpers)

;; this is heavily inspired by nvim-jdtls
(fn open-jdt-file [{:buf bufnr :match uri}]
  (let [timeout-ms 2000]
    (tset (. vim :bo bufnr) :modifiable true)
    (tset (. vim :bo bufnr) :buftype :nofile)
    ;; set filetype and wait for client to attach to the buffer. the name
    ;; "jdtls" must be kept in sync with ftplugin/java.fnl
    (tset (. vim :bo bufnr) :filetype :java)
    (var client nil)
    (vim.wait timeout-ms #(let [clients (vim.lsp.get_active_clients {:name :jdtls
                                                                     : bufnr})]
                            (set client (. clients 1))
                            (> (length clients) 0)))
    (when client
      (var received-cb false)

      (fn handler [err result]
        (if err
            (do
              (error err)
              (set received-cb true))
            (let [lines (vim.split result "\n" {:plain true})]
              (vim.api.nvim_buf_set_lines bufnr 0 -1 true lines)
              (tset (. vim :bo bufnr) :modifiable false)
              (set received-cb true))))

      (client.request :java/classFileContents {: uri} handler bufnr)
      (vim.wait timeout-ms #received-cb))))

(mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__jdtls
            [{:events [:BufReadCmd]
              :targets ["jdt://*"]
              :callback open-jdt-file}])
