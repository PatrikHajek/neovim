-- TODO: Create custom todo picker using standard rg.
-- Highlight results (preview too?)
-- Option for files to search to allow for buffer and project wide searches.
-- Option to show only some labels to filter out NOTE, INFO, ... Add keymap to show all?
-- Option to search by commit date? Allows searching todos chronologically.
-- Todo-comments seems to enable using custom patterns for matching and is already using rg.
-- TODO: Todo textobject: outer is whole todo with comment, inner is the text without label.

vim.keymap.set('n', '<leader>to', function()
  local path = vim.fn.expand '~/notes/inbox.md'
  if vim.api.nvim_buf_get_name(0) == path and #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd.quit()
  else
    vim.cmd.tabedit(path)
  end
end, { desc = '[T]odo [O]pen' })

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
