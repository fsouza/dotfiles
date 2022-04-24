(fn block-on [timeout-ms f ...]
  (var result nil)
  (var done false)
  (let [args [...]]
    (table.insert args (fn [...]
                         (set result [...])
                         (set done true)))
    (f (unpack args)))
  (let [ok (vim.wait timeout-ms #(= done true) 50)]
    (if ok
        result
        (error (string.format "didnt complete after %d ms" timeout-ms)))))

{: block-on}
