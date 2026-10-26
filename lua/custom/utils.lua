local M = {}

M.CHARS_ESCAPE_MAGIC = [[^$.~*+?=@%&\|{}[]()<>]]

-- Gets the start and end marks of the last selection.
--
-- If you run this function while still in visual mode, this will return the contents
-- of the last selection. You must first exit visual mode to get the contents. You
-- can do so like this, for example: `vim.api.nvim_command(':normal v')`.
--
--- @return { start: integer[], end_: integer[] }
M.get_selection_marks = function()
  local mark_start = vim.api.nvim_buf_get_mark(0, '<')
  local mark_end = vim.api.nvim_buf_get_mark(0, '>')
  assert(mark_start[1] ~= 0 and mark_end[1] ~= 0, 'no last selection')
  local start = mark_start
  local end_ = mark_end
  -- orders by column if on the same line
  if mark_start[1] == mark_end[1] then
    start = mark_start[2] < mark_end[2] and mark_start or mark_end
    end_ = mark_start[2] < mark_end[2] and mark_end or mark_start
  else
    start = mark_start[1] < mark_end[1] and mark_start or mark_end
    end_ = mark_start[1] < mark_end[1] and mark_end or mark_start
  end
  -- if you pass a bigger index to string.sub, it will return an empty string
  local string_sub_max = 2147483647 - 1
  start[2] = start[2] > string_sub_max and string_sub_max or start[2]
  end_[2] = end_[2] > string_sub_max and string_sub_max or end_[2]
  return { start = start, end_ = end_ }
end

--- Get the git root for the cwd.
---
--- Returned path always ends with a `/`.
---
--- @param cwd string
--- @return string
M.get_git_root = function(cwd)
  local out = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = cwd }):wait()
  local path = out.stdout
  assert(type(path) == 'string', 'Failed to parse git root command output.')
  path = vim.trim(path)
  if not vim.endswith(path, '/') then
    path = path .. '/'
  end
  return path
end

--- Checks if current buffer is a fugitive buffer.
---
--- @return boolean
M.is_fugitive = function()
  local buf_name = vim.api.nvim_buf_get_name(0)
  return vim.startswith(buf_name, 'fugitive://')
end

--- Preserves cursor column position after running the function.
--- @param func fun()
M.preserve_cursor_column = function(func)
  local pos_old = vim.api.nvim_win_get_cursor(0)
  func()
  vim.defer_fn(function()
    local pos_new = vim.api.nvim_win_get_cursor(0)
    if pos_old[2] > pos_new[2] then
      vim.api.nvim_win_set_cursor(0, { pos_new[1], pos_old[2] })
    end
  end, 2)
end

--- @generic T
--- @param list T[]
--- @param fn fun(item: T): boolean
--- @return integer index index of the item if it's found else -1.
M.tbl_index_of = function(list, fn)
  for i, item in ipairs(list) do
    if fn(item) then
      return i
    end
  end
  return -1
end

return M
