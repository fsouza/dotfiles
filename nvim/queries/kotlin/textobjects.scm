(function_declaration) @function.outer

(lambda_literal) @function.outer

(class_declaration) @class.outer

(function_declaration
  (function_body) @function.inner)

(function_declaration
  (function_value_parameters
    (parameter) @parameter.inner))

(value_arguments
  (value_argument) @parameter.inner)
