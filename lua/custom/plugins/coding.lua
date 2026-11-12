-- TODO: Add markdown integration. Add some treesitter navigation also. Highlight whole line of
-- checked todo.
-- TODO: Update exported or more frequently used function and variable names into big-endian naming.
-- TODO: Add throw statement into @statement in typescript.
-- TODO: Think of some better way to save/see all unsaved buffers.
-- FIX: TODO highlighting in prisma files.
-- TODO: Highlight model in prisma.
-- TODO: keymap to fill current line with as much words from the following without going over
-- colorcolumn. - macro?
-- TODO: Add `@param name type` into key-value pattern textobject.
-- TODO: Add `identifier` textobject. Useful when wanting to jump to function name.
-- TODO: Rename this file to "textobjects.lua".

vim.keymap.set({ 'x', 'o' }, 'iz', function()
  vim.cmd 'normal! \27'
  local is_fugitive = require('custom.utils').is_fugitive()
  local line = vim.api.nvim_get_current_line()
  --- @type string | nil
  local line_trimmed = line:match '^%s*[#/-]+%s*(.+)'
  if line_trimmed and not is_fugitive then
    --- @type string
    local char = line_trimmed:sub(1, 1)
    vim.api.nvim_command('normal g_v0f' .. char)
  else
    vim.api.nvim_command 'normal g_v_'
  end
end, { desc = 'inner line' })
vim.keymap.set({ 'x', 'o' }, 'ilz', '<ESC>m0_v`0', { remap = true, desc = 'up to the start of line' })
vim.keymap.set({ 'x', 'o' }, 'inz', '<ESC>m0g_v`0', { remap = true, desc = 'up to the end of line' })

-- Free up `t` for the `@class` textobject.
vim.keymap.set({ 'x', 'o' }, 'a<leader>t', 'at', { noremap = true, desc = 'tag block' })
vim.keymap.set({ 'x', 'o' }, 'i<leader>t', 'it', { noremap = true, desc = 'tag block' })

local ts = {}

--- @alias textobjects.SelectType "a" | "i"
---
--- @alias textobjects.SelectFallback fun(select_type: textobjects.SelectType)

--- @class textobjects.GotoFallback
--- Go to the next occurrence of this textobject.
--- @field next fun()
--- Go to the previous occurrence of this textobject.
--- @field prev fun()
---
--- @alias textobjects.GotoEnclosingFallback fun()

--- @param capture string
--- @param fallback textobjects.SelectFallback|nil
--- @param info { select_type: textobjects.SelectType }
ts.select_with_fallback = function(capture, fallback, info)
  fallback = fallback or function() end

  local node = vim.treesitter.get_node()
  if node and node:type():find 'comment' then
    fallback(info.select_type)
    return
  end

  local has_captures = require('custom.utils.treesitter').has_captures
  -- This branch also checks for no active parser.
  if not has_captures({ capture:sub(2) }, 'textobjects') then
    fallback(info.select_type)
    return
  end

  local ts_select = require 'nvim-treesitter-textobjects.select'
  ts_select.select_textobject(capture, 'textobjects')
end

--- @param fallback textobjects.GotoFallback?
--- @return fun()
--- @return fun()
ts.prepare_goto_fallback = function(fallback)
  if fallback then
    vim.validate('fallback.next', fallback.next, 'function')
    vim.validate('fallback.prev', fallback.prev, 'function')

    return require('repeatable_move').make_repeatable_move_pair(function()
      vim.cmd 'normal! m`'
      fallback.next()
    end, function()
      vim.cmd 'normal! m`'
      fallback.prev()
    end)
  else
    return function() end, function() end
  end
end

--- @param fn fun()
--- @param captures string[]
---@param query_name string
---@param fallback fun()
ts.goto_with_fallback = function(fn, captures, query_name, fallback)
  local utils = require 'custom.utils.treesitter'
  if not pcall(fn, captures, query_name) or not utils.has_captures(captures, query_name) then
    fallback()
  end
end

--- @param fallback textobjects.GotoEnclosingFallback?
--- @return fun()
ts.prepare_goto_enclosing_fallback = function(fallback)
  if fallback then
    return function()
      return require('nvim-treesitter-textobjects.repeatable_move').make_repeatable_move(function()
        vim.cmd 'normal! m`'
        fallback()
      end) { forward = true }
    end
  else
    return function() end
  end
end

-- [[ Textobjects ]]
--- @class textobjects.Fallbacks
--- @field select textobjects.SelectFallback?
--- @field goto_start textobjects.GotoFallback?
--- @field goto_end textobjects.GotoFallback?
--- @field goto_enclosing_start textobjects.GotoEnclosingFallback?
--- @field goto_enclosing_end textobjects.GotoEnclosingFallback?

--- @param textobject string
--- @param key_start string | false
--- @param key_end string | false
--- @param key_around string | false
--- @param key_inner string | false
--- @param key_enclosing_start (string | false)?
--- @param key_enclosing_end (string | false)?
--- @param opts { name: string?, fallbacks: textobjects.Fallbacks? }?
ts.map = function(textobject, key_start, key_end, key_around, key_inner, key_enclosing_start, key_enclosing_end, opts)
  local ts_move = require 'nvim-treesitter-textobjects.move'
  local ts_repeat_move = require 'nvim-treesitter-textobjects.repeatable_move'
  local move = require 'custom.plugins.treesitter.move'
  local utils = require 'custom.utils.treesitter'

  if key_enclosing_start == nil then
    key_enclosing_start = key_start
  end
  if key_enclosing_end == nil then
    key_enclosing_end = key_end
  end

  opts = opts or {}
  opts.name = opts.name or textobject
  opts.fallbacks = opts.fallbacks or {}

  local capture = '@' .. textobject

  if key_start then
    local fallback_next, fallback_prev = ts.prepare_goto_fallback(opts.fallbacks.goto_start)
    vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_start, function()
      ts.goto_with_fallback(ts_move.goto_next_start, { capture .. '.outer' }, 'textobjects', fallback_next)
    end, { desc = 'Next ' .. opts.name .. ' start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_start, function()
      ts.goto_with_fallback(ts_move.goto_previous_start, { capture .. '.outer' }, 'textobjects', fallback_prev)
    end, { desc = 'Previous ' .. opts.name .. ' start' })
  end

  if key_end then
    local fallback_next, fallback_prev = ts.prepare_goto_fallback(opts.fallbacks.goto_end)
    vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_end, function()
      ts.goto_with_fallback(ts_move.goto_next_end, { capture .. '.outer' }, 'textobjects', fallback_next)
    end, { desc = 'Next ' .. opts.name .. ' end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_end, function()
      ts.goto_with_fallback(ts_move.goto_previous_end, { capture .. '.outer' }, 'textobjects', fallback_prev)
    end, { desc = 'Previous ' .. opts.name .. ' end' })
  end

  if key_around then
    vim.keymap.set({ 'x', 'o' }, 'a' .. key_around, function()
      vim.cmd 'normal! m`'
      ts.select_with_fallback(capture .. '.outer', opts.fallbacks.select, { select_type = 'a' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'an' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_next_start(capture .. '.outer', 'textobjects')
      ts.select_with_fallback(capture .. '.outer', opts.fallbacks.select, { select_type = 'a' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'al' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_previous_start(capture .. '.outer', 'textobjects')
      ts_move.goto_previous_start(capture .. '.outer', 'textobjects')
      ts.select_with_fallback(capture .. '.outer', opts.fallbacks.select, { select_type = 'a' })
    end, { desc = opts.name })
  end

  if key_inner then
    vim.keymap.set({ 'x', 'o' }, 'i' .. key_inner, function()
      vim.cmd 'normal! m`'
      ts.select_with_fallback(capture .. '.inner', opts.fallbacks.select, { select_type = 'i' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'in' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_next_start(capture .. '.inner', 'textobjects')
      ts.select_with_fallback(capture .. '.inner', opts.fallbacks.select, { select_type = 'i' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'il' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_previous_start(capture .. '.inner', 'textobjects')
      ts_move.goto_previous_start(capture .. '.inner', 'textobjects')
      ts.select_with_fallback(capture .. '.inner', opts.fallbacks.select, { select_type = 'i' })
    end, { desc = opts.name })
  end

  if key_enclosing_start then
    local goto_enclosing_start = ts_repeat_move.make_repeatable_move(function()
      move.goto_enclosing_start { query_files = { 'textobjects' }, captures = { textobject .. '.outer' } }
    end)
    local fallback = ts.prepare_goto_enclosing_fallback(opts.fallbacks.goto_enclosing_start)
    vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_enclosing_start, function()
      if utils.has_captures({ textobject .. '.outer' }, 'textobjects') then
        goto_enclosing_start { forward = true }
      else
        fallback()
      end
    end, { desc = 'Enclosing ' .. opts.name .. ' start' })
  end

  if key_enclosing_end then
    local goto_enclosing_end = ts_repeat_move.make_repeatable_move(function()
      move.goto_enclosing_end { query_files = { 'textobjects' }, captures = { textobject .. '.outer' } }
    end)
    local fallback = ts.prepare_goto_enclosing_fallback(opts.fallbacks.goto_enclosing_end)
    vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_enclosing_end, function()
      if utils.has_captures({ textobject .. '.outer' }, 'textobjects') then
        goto_enclosing_end { forward = true }
      else
        fallback()
      end
    end, { desc = 'Enclosing ' .. opts.name .. ' end' })
  end
end

--- @param textobject_next string
--- @param textobject_prev string
--- @param key string
--- @param name string
ts.map_swap = function(textobject_next, textobject_prev, key, name)
  vim.keymap.set('n', '<leader>]' .. key, function()
    require('nvim-treesitter-textobjects.swap').swap_next('@' .. textobject_next)
  end, { desc = name })
  vim.keymap.set('n', '<leader>[' .. key, function()
    require('nvim-treesitter-textobjects.swap').swap_previous('@' .. textobject_prev)
  end, { desc = name })
end

local mini_ai = {}

--- @param id string
--- @return textobjects.SelectFallback
mini_ai.select_fallback = function(id)
  --- @param select_type textobjects.SelectType
  return function(select_type)
    require('mini.ai').select_textobject(select_type, id)
  end
end

--- @param side 'left' | 'right'
--- @param id string
--- @return textobjects.GotoFallback
mini_ai.goto_fallback = function(side, id)
  return {
    next = function()
      require('mini.ai').move_cursor(side, 'a', id, { search_method = 'next' })
    end,
    prev = function()
      require('mini.ai').move_cursor(side, 'a', id, { search_method = 'prev' })
    end,
  }
end

--- @param side 'left' | 'right'
--- @param id string
--- @return textobjects.GotoEnclosingFallback
mini_ai.goto_enclosing_fallback = function(side, id)
  return function()
    require('mini.ai').move_cursor(side, 'a', id, { search_method = 'cover' })
  end
end

--- @param textobject string
--- @param side 'left' | 'right'
--- @param dir 'next' | 'prev'
mini_ai.move = function(textobject, side, dir)
  -- FIX: prev+right and next+left jump backwards.
  local ai = require 'mini.ai'
  local lua = require 'custom.utils.lua'

  --- @type { from: { line: integer, col: integer }, to: { line: integer, col: integer } } | nil
  local region_cov = ai.find_textobject('a', textobject, { search_method = 'cover' })

  local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
  cur_col = cur_col + 1 --@ to convert into 1-indexing
  if region_cov then
    local is_on_edge_left = cur_row == region_cov.from.line and cur_col == region_cov.from.col
    local is_on_edge_right = cur_row == region_cov.to.line and cur_col == region_cov.to.col
    local is_after_edge_left = lua.pos.is_before({ region_cov.from.line, region_cov.from.col }, { cur_row, cur_col })
    local is_before_edge_right = lua.pos.is_before({ cur_row, cur_col }, { region_cov.to.line, region_cov.to.col })
    if
      dir == 'prev' and is_on_edge_left
      or dir == 'prev' and side == 'right' and is_before_edge_right
      or dir == 'next' and is_on_edge_right
      or dir == 'next' and side == 'left' and is_after_edge_left
    then
      region_cov = ai.find_textobject('a', textobject, { search_method = 'cover', n_times = 2 })
    end
  end

  if not region_cov then
    ai.move_cursor(side, 'a', textobject, { search_method = dir })
    return
  end

  --- @type { from: { line: integer, col: integer }, to: { line: integer, col: integer } } | nil
  local region_dir = ai.find_textobject('a', textobject, { search_method = dir })
  if not region_dir then
    ai.move_cursor(side, 'a', textobject, { search_method = 'cover' })
    return
  end

  if
    lua.pos.is_before({ region_cov.from.line, region_cov.from.col }, { region_dir.from.line, region_dir.from.col })
    and lua.pos.is_before({ region_dir.to.line, region_dir.to.col }, { region_cov.to.line, region_cov.to.col })
  then
    ai.move_cursor(side, 'a', textobject, { search_method = dir })
  else
    ai.move_cursor(side, 'a', textobject, { search_method = 'cover' })
  end
end

--- @param textobject string
--- @param key_start string
--- @param key_end string
--- @param start_name string?
--- @param end_name string?
mini_ai.map = function(textobject, key_start, key_end, start_name, end_name)
  local repeat_move = require 'repeatable_move'
  local ts_repeat = require 'nvim-treesitter-textobjects.repeatable_move'

  local start_next, start_prev = repeat_move.make_repeatable_move_pair(function()
    vim.cmd 'normal! m`'
    mini_ai.move(textobject, 'left', 'next')
  end, function()
    vim.cmd 'normal! m`'
    mini_ai.move(textobject, 'left', 'prev')
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_start, start_next, { desc = 'Next ' .. (start_name or key_start) })
  vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_start, start_prev, { desc = 'Previous ' .. (start_name or key_start) })

  local end_next, end_prev = repeat_move.make_repeatable_move_pair(function()
    vim.cmd 'normal! m`'
    mini_ai.move(textobject, 'right', 'next')
  end, function()
    vim.cmd 'normal! m`'
    mini_ai.move(textobject, 'right', 'prev')
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_end, end_next, { desc = 'Next ' .. (end_name or key_end) })
  vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_end, end_prev, { desc = 'Previous ' .. (end_name or key_end) })

  local goto_enclosing_start = ts_repeat.make_repeatable_move(function()
    vim.cmd 'normal! m`'
    require('mini.ai').move_cursor('left', 'a', textobject, { search_method = 'cover' })
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_start, function()
    goto_enclosing_start { forward = true }
  end, { desc = 'Enclosing ' .. (start_name or key_start) })

  local goto_enclosing_end = ts_repeat.make_repeatable_move(function()
    vim.cmd 'normal! m`'
    require('mini.ai').move_cursor('right', 'a', textobject, { search_method = 'cover' })
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_end, function()
    goto_enclosing_end { forward = true }
  end, { desc = 'Enclosing ' .. (end_name or key_end) })
end

return {
  {
    'folke/which-key.nvim',
    init = function()
      require('which-key').add {
        { ']', group = 'Go to next textobject' },
        { '[', group = 'Go to previous textobject' },
        { '^', group = 'Go to enclosing textobject' },
        { ']<leader>', group = 'Less used' },
        { '[<leader>', group = 'Less used' },
        { '^<leader>', group = 'Less used' },
        { '<leader>]', group = 'Swap with next textobject' },
        { '<leader>[', group = 'Swap with previous textobject' },
      }
    end,
  },

  {
    'kiyoon/repeatable-move.nvim',
    init = function()
      local repeat_move = require 'repeatable_move'

      -- [[ LSP ]]
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local bufnr = event.buf

          local lsp_move = require 'custom.plugins.lsp.move'
          local reference_next, reference_prev = repeat_move.make_repeatable_move_pair(lsp_move.goto_reference_next, lsp_move.goto_reference_prev)
          vim.keymap.set({ 'n', 'x' }, ']lr', reference_next, { desc = 'Next reference', buffer = bufnr })
          vim.keymap.set({ 'n', 'x' }, '[lr', reference_prev, { desc = 'Previous reference', buffer = bufnr })
        end,
      })

      local paragraph_next, paragraph_prev = repeat_move.make_repeatable_move_pair(function()
        vim.cmd 'normal! }'
      end, function()
        vim.cmd 'normal! {'
      end)
      vim.keymap.set({ 'n', 'x' }, ']p', paragraph_next, { desc = 'Next paragraph' })
      vim.keymap.set({ 'n', 'x' }, '[p', paragraph_prev, { desc = 'Previous paragraph' })

      --- Return the line above current line, the current line and the line below in this order. If
      --- at the start of end of the buffer, return nil for the above/below line.
      --- @return string? Line above
      --- @return string Line current
      --- @return string? Line below
      local function get_current_line_with_neighbors()
        local cursor = vim.api.nvim_win_get_cursor(0)[1]
        local buf_len = vim.api.nvim_buf_line_count(0)

        local row = math.max(cursor, 2)
        row = math.min(row, buf_len - 3)
        local lines = vim.api.nvim_buf_get_lines(0, row - 2, row + 1, false)
        assert(lines[1])
        assert(lines[2])
        assert(lines[3])

        if cursor == 1 then
          return nil, lines[1], lines[2]
        elseif cursor == buf_len then
          return lines[2], lines[3], nil
        else
          return lines[1], lines[2], lines[3]
        end
      end

      vim.keymap.set({ 'n', 'x' }, '}', function()
        local _, curr, below = get_current_line_with_neighbors()
        if not below then
          return -- is on the last line
        end

        if vim.trim(curr):match '^$' then
          if vim.trim(below):match '^%S+' then
            vim.cmd 'normal! j_'
          else
            vim.cmd 'normal! }{j_'
          end
        else
          if vim.trim(below):match '^$' then
            vim.cmd 'normal! }j_'
          else
            vim.cmd 'normal! }k_'
            local row = vim.api.nvim_win_get_cursor(0)[1]
            local buf_len = vim.api.nvim_buf_line_count(0)
            if row == buf_len - 1 then
              vim.cmd 'normal! j_'
            end
          end
        end
      end, { desc = 'Next paragraph start/end' })
      vim.keymap.set({ 'n', 'x' }, '{', function()
        local above, curr = get_current_line_with_neighbors()
        if not above then
          return -- is on the first line
        end

        if vim.trim(curr):match '^$' then
          if vim.trim(above):match '^%S+' then
            vim.cmd 'normal! k_'
          else
            vim.cmd 'normal! {}k_'
          end
        else
          if vim.trim(above):match '^$' then
            vim.cmd 'normal! {k_'
          else
            vim.cmd 'normal! {j_'
            local row = vim.api.nvim_win_get_cursor(0)[1]
            if row == 2 then
              vim.cmd 'normal! k_'
            end
          end
        end
      end, { desc = 'Previous paragraph start/end' })

      local sentence_next, sentence_prev = repeat_move.make_repeatable_move_pair(function()
        vim.cmd 'normal! )'
      end, function()
        vim.cmd 'normal! ('
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, ']<leader>s', sentence_next, { desc = 'Next sentence' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[<leader>s', sentence_prev, { desc = 'Previous sentence' })

      local misspell_next, misspell_prev = repeat_move.make_repeatable_move_pair(function()
        vim.cmd 'normal! ]s'
      end, function()
        vim.cmd 'normal! [s'
      end)
      vim.keymap.set('n', ']z', misspell_next, { desc = 'Next misspelled word' })
      vim.keymap.set('n', '[z', misspell_prev, { desc = 'Previous misspelled word' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'chrisgrieser/nvim-various-textobjs',
    },
    branch = 'main',
    opts = {
      move = {
        set_jumps = true,
      },
    },
    init = function()
      -- Disable entire built-in ftplugin mappings to avoid conflicts.
      -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
      vim.g.no_plugin_maps = true

      -- [[ Repeat ]]
      local ts_repeat_move = require 'nvim-treesitter-textobjects.repeatable_move'

      -- Repeat movement with ; and ,
      -- ensure ; goes forward and , goes backward regardless of the last direction
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move_next)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_previous)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })

      local move = require 'custom.plugins.treesitter.move'
      vim.keymap.set({ 'n', 'x', 'o' }, '-', function()
        move.goto_enclosing_start()
      end, { desc = 'Enclosing parent start' })
      vim.keymap.set({ 'n', 'x', 'o' }, '+', function()
        move.goto_enclosing_end()
      end, { desc = 'Enclosing parent end' })

      -- TODO: Check out <C-d>/<C-i>/<C-f>, <C-j> in insert mode.
      -- TODO: Add <C-k> to create new line above and move to it in insert mode.
      -- TODO: Add markdown captures.
      -- TODO: Add C# integration.
      local opts = {
        query_files = { 'locals', 'textobjects', 'highlights', 'indents' },
        captures = {
          'indent.begin',
          'local.definition.import',
          'keyword.import',
          'block.outer',
          'statement.outer',
          'class.outer',
          'function.outer',
          'call.outer',
          'parameter.inner',
          'local.definition.var',
          'assignment.outer',
          'attribute.outer',
          -- Prisma.
          'keyword',
          'keyword.type',
        },
        ignored = { 'comment' },
      }
      vim.keymap.set({ 'n', 'x', 'o' }, ')', function()
        require('custom.plugins.treesitter.move').goto_sibling_next_start(opts)
      end, { desc = 'Go to next block in the same depth' })
      vim.keymap.set({ 'n', 'x', 'o' }, '(', function()
        require('custom.plugins.treesitter.move').goto_sibling_prev_start(opts)
      end, { desc = 'Go to previous block in the same depth' })

      ts.map('block', 'b', 'B', 'b', 'b')

      ts.map('yield', 'y', 'Y', 'y', 'y')

      ts.map('statement', 'k', 'K', 'k', false, nil, nil, { name = 'chun[K] (statement)' })

      ts.map('class', 't', 'T', 't', 't', false, false, { name = 'type (class)' })

      ts.map('function', 'm', 'M', 'm', 'm')

      ts.map('call', 'f', 'F', 'f', 'f', nil, nil, {
        fallbacks = {
          select = mini_ai.select_fallback 'call',
          goto_start = mini_ai.goto_fallback('left', 'call'),
          goto_end = mini_ai.goto_fallback('right', 'call'),
          goto_enclosing_start = mini_ai.goto_enclosing_fallback('left', 'call'),
          goto_enclosing_end = mini_ai.goto_enclosing_fallback('right', 'call'),
        },
      })

      ts.map('parameter', 'j', 'J', 'j', 'j', nil, nil, {
        fallbacks = {
          select = mini_ai.select_fallback 'parameter',
          goto_start = mini_ai.goto_fallback('left', 'parameter'),
          goto_end = mini_ai.goto_fallback('right', 'parameter'),
          goto_enclosing_start = mini_ai.goto_enclosing_fallback('left', 'parameter'),
          goto_enclosing_end = mini_ai.goto_enclosing_fallback('right', 'parameter'),
        },
      })
      ts.map_swap('parameter.inner', 'parameter.inner', 'j', 'parameter')

      ts.map('return', 'r', 'R', 'r', 'r')

      ts.map('loop', 'o', 'O', 'o', 'o')

      ts.map('conditional', 'c', 'C', 'c', 'c')

      ts.map('assignment', '=', false, '=', '=', '=')
      vim.keymap.set({ 'x', 'o' }, 'ik', function()
        vim.cmd 'normal! m`'
        if pcall(vim.treesitter.get_parser, 0) then
          require('nvim-treesitter-textobjects.select').select_textobject('@assignment.lhs', 'textobjects')
        else
          require('various-textobjs').key 'inner'
        end
      end, { desc = 'lhs of assignment' })
      vim.keymap.set({ 'x', 'o' }, 'iv', function()
        vim.cmd 'normal! m`'
        if pcall(vim.treesitter.get_parser, 0) then
          require('nvim-treesitter-textobjects.select').select_textobject('@assignment.rhs', 'textobjects')
        else
          require('various-textobjs').value 'inner'
        end
      end, { desc = 'rhs of assignment' })

      ts.map('comment', 'd', false, false, false, false, false)

      ts.map('expression', 'e', 'E', 'e', 'e')
      ts.map_swap('expression.inner', 'expression.inner', 'e', 'expression (inner)')
      ts.map_swap('expression.outer', 'expression.outer', 'E', 'expression (outer)')

      ts.map('list_item', '<leader>l', '<leader>L', '<leader>l', '<leader>l', '<leader>l', '<leader>L', { name = 'markdown list item' })
      ts.map('list_item.unchecked', '<leader>u', false, false, false, '<leader>u', '<leader>U', { name = 'markdown list item unchecked' })

      ts.map('attribute', 'x', 'X', 'x', 'x')
      ts.map_swap('attribute.outer', 'attribute.outer', 'x', 'attribute')
    end,
  },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    dependencies = {
      'kiyoon/repeatable-move.nvim',
      'folke/which-key.nvim',
    },
    config = function()
      local ai = require 'mini.ai'

      ai.setup {
        n_lines = 500,
        search_method = 'cover',
        -- INFO: Can only define 1-letter long keys.
        custom_textobjects = {
          -- Used by treesitter.
          ['b'] = false,
          ['m'] = false,
          ['o'] = false,
          ['c'] = false,
          ['='] = false,
          [' '] = false,
          ['q'] = false,
          ['f'] = false,
          ['a'] = false,

          ['call'] = {
            {
              '%f[%w_%.%:][%w_%.%-%:]+%s*%b()',
              '%f[%w_%.%:][%w_%.%-%:]+%s*%b[]',
            },
            -- Stuff between `()` in mini.ai lua patterns is the capture.
            '^().+()[%(%[].*',
          },
          ['parameter'] = ai.gen_spec.argument(),

          -- These patterns have a limitation of choosing the shorter textobject. That becomes
          -- problematic when having 2 texts both ending on a newline but the second being shorter.
          -- Mini will choose the second shorter text when the textobjects overlap (like on the
          -- separator: `.!?,;:-`), even though the separator belongs to the first sentence.
          -- FIX: Inner sentence breaks on `for-loop`.
          -- TODO: Change to words as well; to disable mappings.
          ['s'] = {
            {
              -- Sentence following another sentence or comment start.
              '[%.%?!#/*][^%w\n]*\n?[^%w\n]*()()%w[^%.%?!]*[%.%?!]+()()',

              -- Sentence following a `--` comment. Can't merge above because it has to be 2 dashes
              -- otherwise `Blah blah - blah - blah.` would match as separate sentences.
              '%-%-[^%w\n]*\n?[^%w\n]*()()%w[^%.%?!]*[%.%?!]+()()',

              -- Sentence at the start of a paragraph.
              '\n\n%W*()()%w[^%.%?!]*[%.%?!]+()()',
            },
          },
          ['S'] = {
            {
              -- Sentence clause following another clause or comment start.
              '[%.%?!#/*,;:%-][^%w\n]*\n?[^%w\n]*()()%w[^%.%?!,;:%-]*[%.%?!,;:%-]+()()',

              -- Sentence clause following a `--` comment. Can't merge above because it has to be 2
              -- dashes otherwise the comment token would be treated as part of the sentence.
              '%-%-[^%w\n]*\n?[^%w\n]*()()%w[^%.%?!,;:%-]*[%.%?!,;:%-]+()()',

              -- Sentence clause at the start of a paragraph.
              '\n\n%W*()()%w[^%.%?!,;:%-]*[%.%?!,;:%-]+()()',
            },
          },

          ['n'] = {
            '()%f[%+%-%.%d][%-%+]?()%d*%.?%d+%f[^%d]()()',
          },
        },
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          vim.keymap.del('n', ']]', { buffer = true })
          vim.keymap.del('n', '[[', { buffer = true })
        end,
      })
      mini_ai.map('(', '(', ')')
      mini_ai.map('[', '[', ']')
      mini_ai.map('{', '{', '}')
      mini_ai.map('<', '<', '>')

      require('which-key').add {
        { "]'", group = "Next '" },
        { "['", group = "Previous '" },
        { ']"', group = 'Next "' },
        { '["', group = 'Previous "' },
        { ']`', group = 'Next `' },
        { '[`', group = 'Previous `' },
      }
      mini_ai.map("'", "'s", "'e", "' start", "' end")
      mini_ai.map('"', '"s', '"e', '" start', '" end')
      mini_ai.map('`', '`s', '`e', '` start', '` end')

      -- Sentence
      mini_ai.map('S', '<leader>s', '<leader>S', 'sentence', 'sentence')
      vim.keymap.set({ 'x', 'o' }, 'a<leader>s', function()
        ai.select_textobject('i', 's')
      end, { desc = 'sentence' })
      vim.keymap.set({ 'x', 'o' }, 'i<leader>s', function()
        ai.select_textobject('i', 'S')
      end, { desc = 'sentence' })

      -- Number
      mini_ai.map('n', '<leader>n', '<leader>N', 'number', 'number')
      vim.keymap.set({ 'x', 'o' }, 'a<leader>n', function()
        ai.select_textobject('a', 'n')
      end, { desc = 'number' })
      vim.keymap.set({ 'x', 'o' }, 'i<leader>n', function()
        ai.select_textobject('i', 'n')
      end, { desc = 'number' })

      -- TODO: Create comment navigation that works on a comment block.
      -- TODO: Remake into custom mini.ai textobject; don't rely on treesitter at all.
      -- TODO: Make `ad` with whitespace (newline), `id` without.
      vim.keymap.set({ 'x', 'o' }, 'ad', require('mini.comment').textobject, { desc = 'comment' })
      vim.keymap.set({ 'x', 'o' }, 'id', require('mini.comment').textobject, { desc = 'comment' })
    end,
  },

  {
    'kylechui/nvim-surround',
    version = '^4.0.0', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      local surround = require 'nvim-surround'
      local config = require 'nvim-surround.config'

      --- @param motion string
      --- @return fun(): selection | nil
      local motion = function(motion)
        return function()
          return config.get_selection { motion = motion }
        end
      end

      --- @generic T
      --- @param list [string[] | nil, T][]
      --- @param lang string
      --- @return T
      local get_by_lang = function(list, lang)
        for _, v in ipairs(vim.list_slice(list, 0, #list - 1)) do
          local langs = v[1]
          assert(langs, 'Default must be put at the end of the list')
          if vim.list_contains(langs, lang) then
            return v[2]
          end
        end

        local default = list[#list]
        assert(not default[1], 'List must contain default at the end')
        return default[2]
      end

      --- @param list [string[] | nil, [ [string], [string]]][]
      --- @return fun(): [ [string], [string]]
      local pairs_per_lang = function(list)
        return function()
          return get_by_lang(list, vim.bo.filetype)
        end
      end

      --- @param list [string[] | nil, string][]
      --- @return fun(char: string | nil): selections | nil
      local patterns_per_lang = function(list)
        return function(char)
          assert(char, "'char' is always provided")
          return config.get_selections { char = char, pattern = get_by_lang(list, vim.bo.filetype) }
        end
      end

      --- @param opts user_surround
      --- @return user_surround
      local create_surround = function(opts)
        return {
          find = opts.find,
          add = opts.add,
          delete = opts.delete,
          change = opts.change or {
            target = opts.delete,
          },
        }
      end

      -- TODO: `call`; make sure it works in comments due to comparing filetypes.
      surround.setup {
        -- Disable default aliases to not mess with custom/textobject surrounds.
        aliases = {
          a = false,
          b = false,
          B = false,
          r = false,
          q = false,
          s = false,
        },

        surrounds = {
          c = create_surround {
            find = motion 'ac',
            add = pairs_per_lang {
              { { 'lua' }, { { 'if x then ' }, { ' end' } } },
              { nil, { { 'if (x) { ' }, { ' }' } } },
            },
            delete = patterns_per_lang {
              { { 'lua' }, '^(if.+then%s*)().-(%s*end)()$' },
              { nil, '^(if.+%{%s*)().-(%s*%})()$' },
            },
          },

          o = create_surround {
            find = motion 'ao',
            add = pairs_per_lang {
              { { 'lua' }, { { 'for x, y in z do ' }, { ' end' } } },
              { nil, { { 'for (x) { ' }, { ' }' } } },
            },
            delete = patterns_per_lang {
              { { 'lua' }, '^(for.+do%s*)().-(%s*end)()$' },
              { nil, '^(for.+%{%s*)().-(%s*%})()$' },
            },
          },

          m = create_surround {
            find = motion 'am',
            add = pairs_per_lang {
              { { 'lua' }, { { 'function() ' }, { ' end' } } },
              { nil, { { 'function() { ' }, { ' }' } } },
            },
            delete = patterns_per_lang {
              { { 'lua' }, '^(.*function.-%(.-%)%s*)().-(%s*end)()$' },
              { nil, '^(function.-%(.-%)%s*%{%s*)().-(%s*%})()$' },
            },
          },

          r = create_surround {
            find = motion 'ar',
            add = pairs_per_lang {
              { nil, { { 'return ' }, { '' } } },
            },
            delete = patterns_per_lang {
              { nil, '^(return%s*)().*()()$' },
            },
          },

          ['='] = create_surround {
            find = motion 'a=',
            -- FIX: Multiline doesn't work.
            delete = patterns_per_lang {
              { nil, '^(.*%=%s*)().*()()$' },
            },
          },
        },
      }

      vim.keymap.set('x', 'z', 'S', { remap = true })
    end,
  },

  {
    'chrisgrieser/nvim-spider',
    lazy = true,
    keys = {
      {
        'w',
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { 'n', 'o', 'x' },
      },
      {
        'e',
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { 'n', 'o', 'x' },
      },
      {
        'b',
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { 'n', 'o', 'x' },
      },
    },
  },

  {
    'chrisgrieser/nvim-various-textobjs',
    config = function()
      --- @param textobject string
      --- @param key_around string | false
      --- @param key_inner string | false
      --- @param desc string?
      local function map(textobject, key_around, key_inner, desc)
        desc = desc and desc or textobject

        if key_around then
          vim.keymap.set({ 'o', 'x' }, 'a' .. key_around, '<cmd>lua require("various-textobjs").' .. textobject .. '("outer")<CR>', { desc = desc })
        end

        if key_inner then
          vim.keymap.set({ 'o', 'x' }, 'i' .. key_inner, '<cmd>lua require("various-textobjs").' .. textobject .. '("inner")<CR>', { desc = desc })
        end
      end

      map('subword', 's', 's')
      -- TODO: Define in mini.ai to have seeking.
      map('url', '<leader>u', '<leader>u')
      map('chainMember', '<leader>m', '<leader>m', 'chain member')
      -- TODO: Define in mini.ai to have seeking.
      map('filepath', '<leader>f', '<leader>f')
      map('diagnostic', '<leader>?', '<leader>?')
      map('indentation', 'i', 'i')
      map('lastChange', '<leader>p', '<leader>p', 'last change')
    end,
  },

  -- TODO: Remove?
  {
    'stevearc/aerial.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
      'kiyoon/repeatable-move.nvim',
    },
    opts = {},
    init = function()
      local repeat_move = require 'repeatable_move'

      local aerial_next, aerial_prev = repeat_move.make_repeatable_move_pair(function()
        vim.cmd 'AerialNext'
      end, function()
        vim.cmd 'AerialPrev'
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, ']<leader>a', aerial_next, { desc = 'Next Aerial symbol' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[<leader>a', aerial_prev, { desc = 'Previous Aerial symbol' })

      vim.keymap.set('n', '<leader>an', ':AerialNavToggle<CR>', { desc = 'Open [A]erial [N]av' })
    end,
  },
}
