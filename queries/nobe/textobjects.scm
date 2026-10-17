;; extends

; Include return types in @return.

(function_literal
  ";" @return.outer
  .
  return_type: _ @return.inner @return.outer)

; Include implicit returns in @return.

(function_literal
  body: (block
    yield: _ @return.inner))

; Add @expression.

(comptime_expression
  _ @expression.inner
  .) @expression.outer

(defer_statement
  _ @expression.inner
  .) @expression.outer

(erasure_expression
  _ @expression.inner
  .) @expression.outer

((call_expression
   function: (field_expression
     value: _? @expression.inner
     field: (builtin_identifier) @_keyword)) @expression.outer
 (#any-of? @_keyword "break" "block" "await"))

(qualified_expression
  _ @expression.inner
  .) @expression.outer

(unary_expression
  _ @expression.inner
  .) @expression.outer

(binary_expression
  left: _ @expression.inner) @expression.outer

(binary_expression
  right: _ @expression.inner)

(spread_expression
  _ @expression.inner
  .) @expression.outer
