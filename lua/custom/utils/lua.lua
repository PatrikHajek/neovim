-- This module defines pure helpers for common patterns specific only to the Lua language, not
-- Neovim or other dependencies.

local M = {}

M.pos = {}

--- Checks if `a` is before `b`.
--- @param a [integer, integer]
--- @param b [integer, integer]
--- @return boolean
M.pos.is_before = function(a, b)
  return a[1] < b[1] or a[1] == b[1] and a[2] < b[2]
end

return M
