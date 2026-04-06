-- To make these keymaps less disorienting when zoomed in.
vim.keymap.set({ 'n', 'x' }, '<C-d>', '5j')
vim.keymap.set({ 'n', 'x' }, '<C-u>', '5k')

vim.keymap.set('x', '>', '>gv')
vim.keymap.set('x', '<', '<gv')

vim.keymap.set({ 'x', 'o' }, 'i_', function()
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
vim.keymap.set({ 'x', 'o' }, 'il_', '<ESC>m0_v`0', { remap = true, desc = 'up to the start of line' })
vim.keymap.set({ 'x', 'o' }, 'in_', '<ESC>m0g_v`0', { remap = true, desc = 'up to the end of line' })

return {
  {
    'folke/which-key.nvim',
    init = function()
      require('which-key').add {
        { ']', group = 'Go to next textobject' },
        { '[', group = 'Go to previous textobject' },
        { '^', group = 'Go to enclosing textobject' },
        { ']g', group = 'Less used' },
        { '[g', group = 'Less used' },
        { '^g', group = 'Less used' },
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
          vim.keymap.set({ 'n', 'x' }, ']r', reference_next, { desc = 'Next reference', buffer = bufnr })
          vim.keymap.set({ 'n', 'x' }, '[r', reference_prev, { desc = 'Previous reference', buffer = bufnr })
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
      vim.keymap.set({ 'n', 'x', 'o' }, ']gs', sentence_next, { desc = 'Next sentence' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[gs', sentence_prev, { desc = 'Previous sentence' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
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

      -- [[ Textobjects ]]
      --- @param textobject string
      --- @param key_start string | false
      --- @param key_end string | false
      --- @param key_around string | false
      --- @param key_inner string | false
      --- @param key_enclosing_start (string | false)?
      --- @param key_enclosing_end (string | false)?
      --- @param opts { name: string? }?
      local function map(textobject, key_start, key_end, key_around, key_inner, key_enclosing_start, key_enclosing_end, opts)
        local ts_move = require 'nvim-treesitter-textobjects.move'
        local ts_select = require 'nvim-treesitter-textobjects.select'
        local move = require 'custom.plugins.treesitter.move'

        if key_enclosing_start == nil then
          key_enclosing_start = key_start
        end
        if key_enclosing_end == nil then
          key_enclosing_end = key_end
        end

        opts = opts or {}
        opts.name = opts.name or textobject

        if key_start then
          vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_start, function()
            ts_move.goto_next_start('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = 'Next ' .. opts.name .. ' start' })
          vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_start, function()
            ts_move.goto_previous_start('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = 'Previous ' .. opts.name .. ' start' })
        end

        if key_end then
          vim.keymap.set({ 'n', 'x', 'o' }, ']' .. key_end, function()
            ts_move.goto_next_end('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = 'Next ' .. opts.name .. ' end' })
          vim.keymap.set({ 'n', 'x', 'o' }, '[' .. key_end, function()
            ts_move.goto_previous_end('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = 'Previous ' .. opts.name .. ' end' })
        end

        if key_around then
          vim.keymap.set({ 'x', 'o' }, 'a' .. key_around, function()
            vim.cmd 'normal! m`'
            ts_select.select_textobject('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = opts.name })

          vim.keymap.set({ 'x', 'o' }, 'an' .. key_around, function()
            vim.cmd 'normal! m`'
            ts_move.goto_next_start('@' .. textobject .. '.outer', 'textobjects')
            ts_select.select_textobject('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = opts.name })

          vim.keymap.set({ 'x', 'o' }, 'al' .. key_around, function()
            vim.cmd 'normal! m`'
            ts_move.goto_previous_start('@' .. textobject .. '.outer', 'textobjects')
            ts_move.goto_previous_start('@' .. textobject .. '.outer', 'textobjects')
            ts_select.select_textobject('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = opts.name })
        end

        if key_inner then
          vim.keymap.set({ 'x', 'o' }, 'i' .. key_inner, function()
            vim.cmd 'normal! m`'
            ts_select.select_textobject('@' .. textobject .. '.inner', 'textobjects')
          end, { desc = opts.name })

          vim.keymap.set({ 'x', 'o' }, 'in' .. key_around, function()
            vim.cmd 'normal! m`'
            ts_move.goto_next_start('@' .. textobject .. '.outer', 'textobjects')
            ts_select.select_textobject('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = opts.name })

          vim.keymap.set({ 'x', 'o' }, 'il' .. key_around, function()
            vim.cmd 'normal! m`'
            ts_move.goto_previous_start('@' .. textobject .. '.outer', 'textobjects')
            ts_move.goto_previous_start('@' .. textobject .. '.outer', 'textobjects')
            ts_select.select_textobject('@' .. textobject .. '.outer', 'textobjects')
          end, { desc = opts.name })
        end

        if key_enclosing_start then
          local enclosing_start = ts_repeat_move.make_repeatable_move(function()
            move.goto_enclosing_start { query_files = { 'textobjects' }, captures = { textobject .. '.outer' } }
          end)
          vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_enclosing_start, enclosing_start, { desc = 'Enclosing ' .. opts.name .. ' start' })
        end

        if key_enclosing_end then
          local enclosing_end = ts_repeat_move.make_repeatable_move(function()
            move.goto_enclosing_end { query_files = { 'textobjects' }, captures = { textobject .. '.outer' } }
          end)
          vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_enclosing_end, enclosing_end, { desc = 'Enclosing ' .. opts.name .. ' end' })
        end
      end

      local move = require 'custom.plugins.treesitter.move'
      vim.keymap.set({ 'n', 'x', 'o' }, '-', function()
        move.goto_enclosing_start()
      end, { desc = 'Enclosing parent start' })
      vim.keymap.set({ 'n', 'x', 'o' }, '+', function()
        move.goto_enclosing_end()
      end, { desc = 'Enclosing parent end' })

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
          'local.definition.var',
          'assignment.outer',
          -- Prisma.
          'keyword',
          'keyword.type',
        },
      }
      vim.keymap.set({ 'n', 'x', 'o' }, ')', function()
        vim.cmd 'normal! m`_'
        require('custom.plugins.treesitter.move').goto_sibling_next_start(opts)
      end, { desc = 'Go to next block in the same depth' })
      vim.keymap.set({ 'n', 'x', 'o' }, '(', function()
        vim.cmd 'normal! m`_'
        require('custom.plugins.treesitter.move').goto_sibling_prev_start(opts)
      end, { desc = 'Go to previous block in the same depth' })

      map('block', 'b', 'B', 'b', 'b')

      map('statement', 's', 'S', 's', false)
      vim.keymap.set('n', ']z', ']s', { desc = 'Next misspelled word' })
      vim.keymap.set('n', '[z', '[s', { desc = 'Previous misspelled word' })

      map('class', 'gc', 'gC', 'gc', 'gc')

      map('function', 'm', 'M', 'm', 'm')

      map('call', 'f', 'F', false, false, 'f', 'F')

      map('parameter', 'a', 'A', false, false)

      map('return', 'gr', 'gR', 'gr', 'gr')

      map('loop', 'o', 'O', 'o', 'o')

      map('conditional', 'c', 'C', 'c', 'c')

      map('assignment', false, false, '=', '=', '=')
      vim.keymap.set({ 'x', 'o' }, 'in=', function()
        vim.cmd 'normal! m`'
        require('nvim-treesitter-textobjects.select').select_textobject('@assignment.rhs', 'textobjects')
      end, { desc = 'rhs of assignment' })
      vim.keymap.set({ 'x', 'o' }, 'il=', function()
        vim.cmd 'normal! m`'
        require('nvim-treesitter-textobjects.select').select_textobject('@assignment.lhs', 'textobjects')
      end, { desc = 'lhs of assignment' })

      map('comment', 'gn', false, false, false, false, false)

      map('list_item', 'gl', 'gL', 'gl', 'gl', 'gl', 'gL', { name = 'markdown list item' })
      map('list_item.unchecked', 'gu', false, false, false, 'gu', 'gU', { name = 'markdown list item unchecked' })

      -- [[ Swap ]]
      vim.keymap.set('n', '<leader>ta', function()
        require('nvim-treesitter-textobjects.swap').swap_next '@parameter.inner'
      end, { desc = 'Swap parameter with the next one' })
      vim.keymap.set('n', '<leader>tA', function()
        require('nvim-treesitter-textobjects.swap').swap_previous '@parameter.outer'
      end, { desc = 'Swap parameter with the previous one' })
    end,
  },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    dependencies = {
      'kiyoon/repeatable-move.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      local ai = require 'mini.ai'

      --- @param textobject string
      --- @param fallback fun()
      local function treesitter_with_fallback(textobject, fallback)
        return function(ai_type)
          local ts_spec = ai.gen_spec.treesitter {
            a = '@' .. textobject .. '.outer',
            i = '@' .. textobject .. '.inner',
          }
          local ok, ts_match = pcall(ts_spec, ai_type)
          if ok and ts_match then
            return ts_match
          else
            return fallback()
          end
        end
      end

      ai.setup {
        n_lines = 500,
        search_method = 'cover',
        custom_textobjects = {
          -- Used by treesitter.
          ['s'] = false,
          ['b'] = false,
          ['m'] = false,
          ['o'] = false,
          ['c'] = false,
          ['='] = false,
          ['_'] = false,
          ['f'] = treesitter_with_fallback('call', ai.gen_spec.function_call),
          ['a'] = treesitter_with_fallback('parameter', ai.gen_spec.argument),
        },
      }

      --- @param textobject string
      --- @param key_start string
      --- @param key_end string
      --- @param start_name string?
      --- @param end_name string?
      local function map(textobject, key_start, key_end, start_name, end_name)
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
        vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_start, goto_enclosing_start, { desc = 'Enclosing ' .. (start_name or key_start) })

        local goto_enclosing_end = ts_repeat.make_repeatable_move(function()
          vim.cmd 'normal! m`'
          require('mini.ai').move_cursor('right', 'a', textobject, { search_method = 'cover' })
        end)
        vim.keymap.set({ 'n', 'x', 'o' }, '^' .. key_end, goto_enclosing_end, { desc = 'Enclosing ' .. (end_name or key_end) })
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          vim.keymap.del('n', ']]', { buffer = true })
          vim.keymap.del('n', '[[', { buffer = true })
        end,
      })
      map('(', '(', ')')
      map('[', '[', ']')
      map('{', '{', '}')
      map('<', '<', '>')

      require('which-key').add {
        { "]'", group = "Next '" },
        { "['", group = "Previous '" },
        { ']"', group = 'Next "' },
        { '["', group = 'Previous "' },
        { ']`', group = 'Next `' },
        { '[`', group = 'Previous `' },
      }
      map("'", "'s", "'e", "' start", "' end")
      map('"', '"s', '"e', '" start', '" end')
      map('`', '`s', '`e', '` start', '` end')

      vim.keymap.set({ 'x', 'o' }, 'ign', require('mini.comment').textobject, { desc = 'comment' })

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
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
      map('url', 'u', 'u')
      map('chainMember', 'gm', 'gm', 'chain member')
      map('filepath', 'gf', 'gf')
    end,
  },

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
      vim.keymap.set({ 'n', 'x', 'o' }, ']ga', aerial_next, { desc = 'Next Aerial symbol' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[ga', aerial_prev, { desc = 'Previous Aerial symbol' })

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
      vim.keymap.set('n', ']gt', todo_next, { desc = 'Next todo comment' })
      vim.keymap.set('n', '[gt', todo_prev, { desc = 'Previous todo comment' })
    end,
  },
}
