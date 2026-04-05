local M = {}

--- Return `a` if `condition` is truthy, otherwise return `b`.
---
--- @generic TResultA
--- @generic TResultB
--- @param condition any
--- @param a TResultA
--- @param b TResultB
--- @return TResultA | TResultB
M.if_else = function(condition, a, b)
  if condition then
    return a
  else
    return b
  end
end

return M
