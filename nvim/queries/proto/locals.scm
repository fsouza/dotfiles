(enum
  (enum_name
    (identifier) @definition.enum)
  (enum_body
    (enum_field
      (identifier) @definition.field)))

(message
  (message_name
    (identifier) @definition.type)

  (message_body
    (field
      (identifier) @definition.field)))
