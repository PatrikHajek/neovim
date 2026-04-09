;; inherits: html

(template_element) @function.outer

(template_element
  (start_tag)
  .
  (_) @function.inner
  .
  (end_tag))

(directive_attribute) @attribute.outer
