return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    columns = {
      'size',
      'icon',
    },
    keymaps = {
      ['_'] = false,
      ['~'] = false,
      ['gh'] = { 'actions.toggle_hidden', mode = 'n' },
      ['gr'] = { 'actions.open_cwd', mode = 'n' },
      ['g.'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
    },
  },
  config = function(_, opts)
    local oil = require 'oil'
    oil.setup(opts)

    local dir = nil
    vim.keymap.set('n', '<leader>e', function()
      if dir then
        oil.open_float(dir)
        dir = nil
        return
      end

      local is_oil = vim.api.nvim_buf_get_name(0):sub(1, 6) == 'oil://'
      if is_oil then
        dir = oil.get_current_dir()
      end
      oil.toggle_float()
    end, { desc = 'Open [E]xplorer' })
  end,
}
