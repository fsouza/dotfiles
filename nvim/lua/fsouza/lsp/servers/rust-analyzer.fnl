(fn valid-diagnostic [d]
  (let [severity (or (. d :severity) 0)]
    (< severity 4)))

{: valid-diagnostic}
