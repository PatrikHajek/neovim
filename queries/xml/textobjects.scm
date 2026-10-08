(element) @function.outer

(element
  (content) @function.inner)

(Attribute) @attribute.outer

((AttValue) @attribute.inner
 (#offset! @attribute.inner 0 1 0 -1))

(Comment) @comment.outer
