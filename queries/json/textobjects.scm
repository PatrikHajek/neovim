;; extends

; Parameters

(object
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(object
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

(array
  .
  _ @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(array
  "," @parameter.outer
  .
  _ @parameter.inner @parameter.outer)

; assignments

(pair
  key: (string
    (string_content) @assignment.inner @assignment.lhs)
  value: _ @assignment.inner) @assignment.outer

(pair
  value: _ @assignment.rhs)
