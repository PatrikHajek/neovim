-- TODO: Add markdown integration. Add some treesitter navigation also. Highlight whole line of
-- checked todo.
-- TODO: Update exported or more frequently used function and variable names into big-endian naming.
-- TODO: Add throw statement into @statement in typescript.
-- TODO: Think of some better way to save/see all unsaved buffers.
-- FIX: TODO highlighting in prisma files.
-- TODO: Highlight model in prisma.

-- To make these keymaps less disorienting when zoomed in.
vim.keymap.set({ 'n', 'x' }, '<C-d>', '10j')
vim.keymap.set({ 'n', 'x' }, '<C-u>', '10k')

vim.keymap.set('x', '>', '>gv')
vim.keymap.set('x', '<', '<gv')

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

--- @param capture string
--- @param fallback string|nil
--- @param info { ai_type: "a" | "i" }
ts.select_with_fallback = function(capture, fallback, info)
  local ts_select = require 'nvim-treesitter-textobjects.select'
  if not pcall(ts_select.select_textobject, capture, 'textobjects') and fallback then
    require('mini.ai').select_textobject(info.ai_type, fallback)
  end
end

--- @class textobjects.GotoOpts
--- Go to the next occurrence of this textobject.
--- @field next fun()
--- Go to the previous occurrence of this textobject.
--- @field prev fun()
---
--- @alias textobjects.GotoEnclosingOpts fun()

--- @param fallback textobjects.GotoOpts?
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

--- @param fallback textobjects.GotoEnclosingOpts?
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
--- @field select string?
--- @field goto_start textobjects.GotoOpts?
--- @field goto_end textobjects.GotoOpts?
--- @field goto_enclosing_start textobjects.GotoEnclosingOpts?
--- @field goto_enclosing_end textobjects.GotoEnclosingOpts?

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
      if not pcall(ts_move.goto_next_start, { capture .. '.outer' }, 'textobjects') then
        fallback_next()
      end
    end, { desc = 'Next ' .. opts.name .. ' start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_start, function()
      if not pcall(ts_move.goto_previous_start, { capture .. '.outer' }, 'textobjects') then
        fallback_prev()
      end
    end, { desc = 'Previous ' .. opts.name .. ' start' })
  end

  if key_end then
    local fallback_next, fallback_prev = ts.prepare_goto_fallback(opts.fallbacks.goto_end)
    vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_end, function()
      if not pcall(ts_move.goto_next_end, { capture .. '.outer' }, 'textobjects') then
        fallback_next()
      end
    end, { desc = 'Next ' .. opts.name .. ' end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_end, function()
      if not pcall(ts_move.goto_previous_end, { capture .. '.outer' }, 'textobjects') then
        fallback_prev()
      end
    end, { desc = 'Previous ' .. opts.name .. ' end' })
  end

  if key_around then
    vim.keymap.set({ 'x', 'o' }, 'a' .. key_around, function()
      vim.cmd 'normal! m`'
      ts.select_with_fallback(capture .. '.outer', opts.fallbacks.select, { ai_type = 'a' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'an' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_next_start(capture .. '.outer', 'textobjects')
      ts.select_with_fallback(capture .. '.outer', opts.fallbacks.select, { ai_type = 'a' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'al' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_previous_start(capture .. '.outer', 'textobjects')
      ts_move.goto_previous_start(capture .. '.outer', 'textobjects')
      ts.select_with_fallback(capture .. '.outer', opts.fallbacks.select, { ai_type = 'a' })
    end, { desc = opts.name })
  end

  if key_inner then
    vim.keymap.set({ 'x', 'o' }, 'i' .. key_inner, function()
      vim.cmd 'normal! m`'
      ts.select_with_fallback(capture .. '.inner', opts.fallbacks.select, { ai_type = 'i' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'in' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_next_start(capture .. '.inner', 'textobjects')
      ts.select_with_fallback(capture .. '.inner', opts.fallbacks.select, { ai_type = 'i' })
    end, { desc = opts.name })

    vim.keymap.set({ 'x', 'o' }, 'il' .. key_around, function()
      vim.cmd 'normal! m`'
      ts_move.goto_previous_start(capture .. '.inner', 'textobjects')
      ts_move.goto_previous_start(capture .. '.inner', 'textobjects')
      ts.select_with_fallback(capture .. '.inner', opts.fallbacks.select, { ai_type = 'i' })
    end, { desc = opts.name })
  end

  if key_enclosing_start then
    local goto_enclosing_start = ts_repeat_move.make_repeatable_move(function()
      move.goto_enclosing_start { query_files = { 'textobjects' }, captures = { textobject .. '.outer' } }
    end)
    local fallback = ts.prepare_goto_enclosing_fallback(opts.fallbacks.goto_enclosing_start)
    vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_enclosing_start, function()
      if pcall(vim.treesitter.get_parser, 0) then
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
      if pcall(vim.treesitter.get_parser, 0) then
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

--- @return textobjects.GotoOpts
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

--- @return textobjects.GotoEnclosingOpts
mini_ai.goto_enclosing_fallback = function(side, id)
  return function()
    require('mini.ai').move_cursor(side, 'a', id, { search_method = 'cover' })
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

  local next_start, prev_start = repeat_move.make_repeatable_move_pair(function()
    vim.cmd 'normal! m`'
    require('mini.ai').move_cursor('left', 'a', textobject, { search_method = 'next' })
  end, function()
    vim.cmd 'normal! m`'
    require('mini.ai').move_cursor('left', 'a', textobject, { search_method = 'prev' })
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_start, next_start, { desc = 'Next ' .. (start_name or key_start) })
  vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_start, prev_start, { desc = 'Previous ' .. (start_name or key_start) })

  local next_end, prev_end = repeat_move.make_repeatable_move_pair(function()
    vim.cmd 'normal! m`'
    require('mini.ai').move_cursor('right', 'a', textobject, { search_method = 'next' })
  end, function()
    vim.cmd 'normal! m`'
    require('mini.ai').move_cursor('right', 'a', textobject, { search_method = 'prev' })
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_end, next_end, { desc = 'Next ' .. (end_name or key_end) })
  vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_end, prev_end, { desc = 'Previous ' .. (end_name or key_end) })

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

      ts.map('statement', 's', 'S', 's', false)
      vim.keymap.set('n', ']z', ']s', { desc = 'Next misspelled word' })
      vim.keymap.set('n', '[z', '[s', { desc = 'Previous misspelled word' })

      ts.map('class', 't', 'T', 't', 't', false, false, { name = 'type (class)' })

      ts.map('function', 'm', 'M', 'm', 'm')

      ts.map('call', 'f', 'F', 'f', 'f', nil, nil, {
        fallbacks = {
          select = 'f',
          goto_start = mini_ai.goto_fallback('left', 'f'),
          goto_end = mini_ai.goto_fallback('right', 'f'),
          goto_enclosing_start = mini_ai.goto_enclosing_fallback('left', 'f'),
          goto_enclosing_end = mini_ai.goto_enclosing_fallback('right', 'f'),
        },
      })

      ts.map('parameter', 'a', 'A', 'a', 'a', nil, nil, {
        fallbacks = {
          select = 'a',
          goto_start = mini_ai.goto_fallback('left', 'a'),
          goto_end = mini_ai.goto_fallback('right', 'a'),
          goto_enclosing_start = mini_ai.goto_enclosing_fallback('left', 'a'),
          goto_enclosing_end = mini_ai.goto_enclosing_fallback('right', 'a'),
        },
      })
      ts.map_swap('parameter.inner', 'parameter.inner', 'a', 'parameter')

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

      ts.map('comment', '<leader>c', false, false, false, false, false)

      ts.map('expression', 'e', 'E', 'e', 'e')

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

          ['f'] = {
            {
              '%f[%w%.%:][%w%.%-%:]+%s*%b()',
              '%f[%w%.%:][%w%.%-%:]+%s*%b[]',
            },
            -- Stuff between `()` in mini.ai lua patterns is the capture.
            '^().+()[%(%[].*',
          },
          ['a'] = ai.gen_spec.argument(),

          -- These patterns have a limitation of choosing the shorter textobject. That becomes
          -- problematic when having 2 texts both ending on a newline but the second being shorter.
          -- Mini will choose the second shorter text when the textobjects overlap (like on the
          -- separator: `.!?,;:-`), even though the separator belongs to the first sentence.
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
      mini_ai.map('S', '<leader>s', '<leader>S')
      vim.keymap.set({ 'x', 'o' }, 'a<leader>s', function()
        ai.select_textobject('i', 's')
      end)
      vim.keymap.set({ 'x', 'o' }, 'i<leader>s', function()
        ai.select_textobject('i', 'S')
      end)

      -- TODO: Create comment navigation that works on a comment block.
      vim.keymap.set({ 'x', 'o' }, 'a<leader>c', require('mini.comment').textobject, { desc = 'comment' })
      vim.keymap.set({ 'x', 'o' }, 'i<leader>c', require('mini.comment').textobject, { desc = 'comment' })
    end,
  },

  {
    'kylechui/nvim-surround',
    version = '^4.0.0', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
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

      map('subword', false, 's')
      map('url', '<leader>u', '<leader>u')
      map('chainMember', '<leader>m', '<leader>m', 'chain member')
      map('filepath', '<leader>f', '<leader>f')
      map('diagnostic', '<leader>?', '<leader>?')
      map('number', '<leader>n', '<leader>n')
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

  {
    'numToStr/Comment.nvim',
    opts = {},
  },

  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'kiyoon/repeatable-move.nvim',
    },
    opts = { signs = false },
    init = function()
      vim.keymap.set('n', '<leader>tt', ':TodoTelescope<CR>', { desc = 'Search [T]odos using [T]elescope' })
      vim.keymap.set('n', '<leader>lt', ':Trouble todo<CR>', { desc = '[L]ist [T]odos' })

      local repeat_move = require 'repeatable_move'
      local todo_next, todo_prev = repeat_move.make_repeatable_move_pair(function()
        require('todo-comments').jump_next()
      end, function()
        require('todo-comments').jump_prev()
      end)
      vim.keymap.set('n', ']<leader>t', todo_next, { desc = 'Next todo comment' })
      vim.keymap.set('n', '[<leader>t', todo_prev, { desc = 'Previous todo comment' })
    end,
  },
}
