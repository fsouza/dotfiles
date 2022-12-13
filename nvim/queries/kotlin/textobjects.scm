(function_declaration) @function.outer

(lambda_literal) @function.outer

(class_declaration) @class.outer

(function_declaration
  (function_body
    (statements) @function.inner))

(function_declaration
  (parameter) @parameter.inner)
