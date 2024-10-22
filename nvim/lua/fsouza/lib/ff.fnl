(local features {})

(fn disable [feature]
  (tset features feature false))

(fn enable [feature]
  (tset features feature true))

(fn is-enabled [feature ?default]
  (let [v (. features feature)]
    (if (not= v nil)
        v
        ?default)))

{: disable : enable : is-enabled}
