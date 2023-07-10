(local features {})

(lambda disable [feature]
  (tset features feature false))

(lambda enable [feature]
  (tset features feature true))

(lambda is-enabled [feature ?default]
  (let [v (. features feature)]
    (if (not= v nil)
        v
        ?default)))

{: disable : enable : is-enabled}
