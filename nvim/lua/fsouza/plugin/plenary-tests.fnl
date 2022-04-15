(import-macros {: mod-invoke : if-nil} :helpers)

(macro test-dir []
  `(if-nil vim.env.PLENARY_TEST_DIR
           (mod-invoke :pl.path :join config-dir :tests)))

(fn run-tests []
  (let [test-harness (require :plenary.test_harness)]
    (test-harness.test_directory (test-dir) {})))

{: run-tests}
