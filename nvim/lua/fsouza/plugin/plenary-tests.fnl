(import-macros {: mod-invoke } :helpers)

(macro test-dir []
  `(mod-invoke :fsouza.pl.path :join config-dir :tests))

(fn run-tests []
  (let [test-harness (require :plenary.test_harness)]
    (test-harness.test_directory (test-dir) {})))

{: run-tests}
