local M = {}

--- @param node TSNode
--- @param queries { [string]: vim.treesitter.Query }
--- @param captures string[]
--- @return string | nil capture The first capture from captures that is queried or nil.
local function get_capture(node, queries, captures)
  local scope = node:parent()
  -- All nodes have a parent except "program", which won't match may capture.
  if not scope then
    return
  end

  -- Use node's range if parent is the whole tree to save on performance. Don't think this breaks
  -- any captures as no capture probably relies on "program" node.
  if not scope:parent() then
    scope = node
  end

  for _, query in pairs(queries) do
    for id, matched_node in query:iter_captures(scope, 0) do
      local capture = query.captures[id]
      if vim.list_contains(captures, capture) and matched_node == node then
        return capture
      end
    end
  end

  return nil
end

--- @param node TSNode
--- @param queries { [string]: vim.treesitter.Query }
--- @param captures string[]
--- @return TSNode?
local function get_node_captured(node, queries, captures)
  local node_row, node_col = node:range()
  --- @type TSNode?
  local n = node
  while n do
    local n_row, n_col = n:range()
    if get_capture(n, queries, captures) ~= nil and node_row == n_row and node_col == n_col then
      return n
    end
    n = n:parent()
  end
end

--- @param query_files string[]
--- @param node TSNode
--- @return { [string]: vim.treesitter.Query }
local function prepare_queries(query_files, node)
  local root_parser = vim.treesitter.get_parser(0)
  if not root_parser then
    return {}
  end

  local start_row, start_col, end_row, end_col = node:range()
  local lang = root_parser:language_for_range({ start_row, start_col, end_row, end_col }):lang()

  local queries = {}
  for _, query_file in ipairs(query_files) do
    local query = vim.treesitter.query.get(lang, query_file)
    if query then
      queries[query_file] = query
    end
  end

  return queries
end

--- @class treesitter_get_enclosing_opts
--- @field query_files string[]
--- @field captures string[]

--- Climbs up the tree of parents of the node under the cursor including itself. Returns the node
--- where `predicate` is true.
---
--- Ignores parents that don't match the `captures`. If `opts` is omitted, the innermost parent is
--- targeted.
---
--- @param opts treesitter_get_enclosing_opts?
--- @param predicate fun(curr: TSNode, init: TSNode): boolean
--- @return TSNode | nil
local function get_enclosing(opts, predicate)
  local node = vim.treesitter.get_node { ignore_injections = false }
  if not node then
    return
  end

  local queries = opts and prepare_queries(opts.query_files, node) or {}

  --- @type TSNode?
  local curr = node
  while curr do
    if predicate(curr, node) then
      if opts then
        if get_capture(curr, queries, opts.captures) ~= nil then
          return curr
        end
      else
        return curr
      end
    end
    curr = curr:parent()
  end
end

--- @param opts treesitter_get_enclosing_opts?
M.goto_enclosing_start = function(opts)
  local node = get_enclosing(opts, function(curr)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local c_row = curr:range()
    -- "block" nodes start on the first line in the block and are masking the real parent.
    return curr:type() ~= 'block' and (cursor ~= c_row + 1 or curr:parent() == nil)
  end)
  if node then
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local row, col = node:range()
    vim.cmd 'normal! m`'
    vim.api.nvim_win_set_cursor(0, { row + 1, col })

    -- The following code ensures that you can get out of injected trees using enclosing nav.

    -- Is at the top of the tree (injected or not).
    if node:parent() == nil and cursor_row == row + 1 then
      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local line = vim.api.nvim_get_current_line()
      local char_col = line:sub(1, cursor_col):find '(%S)%s*$' or cursor_col + 1
      char_col = char_col - 1
      vim.api.nvim_win_set_cursor(0, { cursor_row, char_col })

      if cursor_col == char_col then
        vim.cmd 'normal! k'
      end
    end
  end
end

--- @param opts treesitter_get_enclosing_opts?
M.goto_enclosing_end = function(opts)
  local node = get_enclosing(opts, function(curr)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local _, _, c_row = curr:range()
    return cursor ~= c_row + 1 or curr:parent() == nil
  end)
  if node then
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local _, _, row, col = node:range()
    vim.cmd 'normal! m`'
    local line_count = vim.api.nvim_buf_line_count(0)
    row = math.min(line_count - 1, row)
    vim.api.nvim_win_set_cursor(0, { row + 1, math.max(0, col - 1) })

    -- The following code ensures that you can get out of injected trees using enclosing nav.

    -- Is at the top of the tree (injected or not).
    if node:parent() == nil and cursor_row == row + 1 then
      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local line = vim.api.nvim_get_current_line()
      local char_col = line:sub(cursor_col + 2):find '^%s*(%S)' or 1
      -- Adding 1 to not end up on the end of root node.
      char_col = cursor_col + char_col + 1
      vim.api.nvim_win_set_cursor(0, { cursor_row, char_col })
    end
  end
end

--- @class treesitter_get_sibling_opts
--- @field query_files string[]
--- @field captures string[]
--- @field ignored string[]?

--- Finds the sibling where `predicate` is true. If no direct sibling exists, goes up to the parent
--- and uses it's sibling. Repeats this until it finds a sibling or reaches the root, in which case
--- it returns nil.
---
--- Ignores siblings that don't match the `captures`. If `opts` is omitted, any siblings passes.
---
--- @param opts treesitter_get_sibling_opts?
--- @param dir "next" | "prev"
--- @param predicate fun(curr: TSNode, init: TSNode): boolean
--- @return TSNode | nil
local function get_sibling(opts, dir, predicate)
  local node = vim.treesitter.get_node { ignore_injections = false }
  if not node then
    return
  end

  local queries = opts and prepare_queries(opts.query_files, node) or {}

  --- @type TSNode?
  local curr = opts and get_node_captured(node, queries, opts.captures) or node
  local parent = curr and curr:parent()
  while parent do
    while curr do
      -- "block" nodes start on the first line in the block and interfering with the real siblings.
      if curr:type() ~= 'block' and predicate(curr, node) then
        if opts then
          if get_capture(curr, queries, opts.captures) ~= nil and (not opts.ignored or get_capture(curr, queries, opts.ignored) == nil) then
            return curr
          end
        else
          return curr
        end
      end

      if dir == 'next' then
        curr = curr:next_named_sibling()
      elseif dir == 'prev' then
        curr = curr:prev_named_sibling()
      else
        error('Unknown option: ' .. tostring(dir))
      end
    end
    curr = opts and get_node_captured(parent, queries, opts.captures) or parent
    parent = curr and curr:parent()
  end
end

--- @param opts treesitter_get_sibling_opts?
M.goto_sibling_next_start = function(opts)
  local node_cursor = vim.treesitter.get_node { ignore_injections = false }
  if not node_cursor or not node_cursor:parent() then
    vim.cmd 'normal! }{j_'
    return
  end

  local node = get_sibling(opts, 'next', function(curr)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local c_row = curr:range()
    return cursor < c_row + 1
  end)
  if node then
    local row, col = node:range()
    vim.cmd 'normal! m`'
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
  end
end

--- @param opts treesitter_get_sibling_opts?
M.goto_sibling_prev_start = function(opts)
  local node_cursor = vim.treesitter.get_node { ignore_injections = false }
  if not node_cursor or not node_cursor:parent() then
    vim.cmd 'normal! {}k_'
    return
  end

  local node = get_sibling(opts, 'prev', function(curr)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local c_row = curr:range()
    return cursor > c_row + 1
  end)
  if node then
    local row, col = node:range()
    vim.cmd 'normal! m`'
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
  end
end

return M
