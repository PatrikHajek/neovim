local M = {}

--- Checks if the query file has defined any of the captures.
---
--- @param captures string[]
--- @param query_name string
--- @return boolean
M.has_captures = function(captures, query_name)
  local root_parser = vim.treesitter.get_parser(0)
  if not root_parser then
    return false
  end

  local node = vim.treesitter.get_node()
  if not node then
    return false
  end

  local start_row, start_col, end_row, end_col = node:range()
  local lang = root_parser:language_for_range({ start_row, start_col, end_row, end_col }):lang()
  local query = vim.treesitter.query.get(lang, query_name)
  if not query then
    return false
  end

  return vim.iter(query.captures):any(function(v)
    return vim.tbl_contains(captures, v)
  end)
end

return M
