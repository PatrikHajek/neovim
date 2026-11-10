return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      open_mapping = '<C-t>',
      direction = 'tab',
      auto_scroll = false,
      on_open = function()
        vim.opt.scrolloff = 1000
      end,
      -- insert_mappings = false,
      -- shade_terminals = true,
      -- hide_numbers = false,

      -- autochdir = true,
    }

    -- mappings
    -- vim.keymap.set("n", "<leader>to", ":ToggleTerm direction=float<CR>", { desc = "Toggle Terminal in Floating Window" })
    -- vim.keymap.set("n", "<leader>tO", ":ToggleTerm direction=tab<CR>", { desc = "Toggle Terminal in Normal Mode" })
    vim.keymap.set('t', '<C-x>', '<esc><bar><C-\\><C-n>', { desc = 'Exit terminal mode' })
  end,
}
