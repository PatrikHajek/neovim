return {
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'kiyoon/repeatable-move.nvim',
    },
    opts = {
      signs = false,
      highlight = {
        -- To allow todo comments in markdown and text files. Could highlight in code also though.
        -- comments_only = false,
      },
    },
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
