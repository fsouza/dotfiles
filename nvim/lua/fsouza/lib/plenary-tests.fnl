(import-macros {: mod-invoke} :helpers)

(macro test-dir []
  `(mod-invoke :fsouza.pl.path :join _G.config-dir :tests))

(fn run-tests []
  (let [test-harness (require :plenary.test_harness)]
    (test-harness.test_directory (test-dir) {})))

{: run-tests}
