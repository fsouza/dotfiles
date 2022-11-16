(namespace
  (identifier) @definition.namespace)

(definition
  [
   (const
     (identifier) @definition.constant)
   (enum
     (identifier) @definition.enum)
    (struct
      (identifier) @definition.type
      (field
	(identifier) @definition.field))
    (typedef
      (identifier) @definition.type)
    (exception
      (identifier) @definition.type)
  ]
)
