(local features {})

(lambda disable [feature]
  (tset features feature false))

(lambda enable [feature]
  (tset features feature true))

(lambda is-enabled [feature ?default]
  (or (. features feature) ?default))

{: disable : enable : is-enabled}
