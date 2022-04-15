(import-macros {: mod-invoke} :helpers)

(macro test-dir []
  `(mod-invoke :pl.path :join config-dir :tests :plenary))

(fn run-tests []
  (let [test-harness (require :plenary.test_harness)]
    (test-harness.test_directory (test-dir) {})))

{: run-tests}
