return {
  {
    'olimorris/onedarkpro.nvim',
    priority = 1000, -- Ensure it loads first
    config = function()
      local colors = require('onedarkpro.helpers').get_colors 'onedark_vivid'
      require('onedarkpro').setup {
        -- NOTE: for a list of possible values, run `h attr-list`
        highlights = {
          -- TelescopeSelection was set to purple fg and black bg before upgrading. Currently, when
          -- setting fg, it will overwrite the TelescopeMatching - won't highlight matched chars.
          TelescopeMatching = { fg = colors.purple, bold = true },
          TelescopeSelection = { bg = colors.black },
          -- TODO: Style Telescope titles?
          -- TelescopePreviewTitle = { fg = colors.black, bg = colors.blue, bold = true },
          -- TelescopePromptTitle = { fg = colors.black, bg = colors.red, bold = true },

          -- #516c56 corresponds to the 20% mark between #43554d (GitsignsAddInline) and #89CA78
          -- (@string).
          GitsignsAddInline = { bg = '#516c56' },
          GitsignsChangeInline = { bg = '#516c56' },

          ['@markup.list.checked.markdown'] = { fg = colors.purple },
          SpellBad = { fg = colors.green },
          SpellLocal = { fg = colors.green },
          -- SpellBad = { underdashed = true },

          -- Lua
          ['@lsp.type.variable.lua'] = {},

          -- Scala
          ['@lsp.type.parameter.scala'] = { link = '@variable.parameter' },
          ['@lsp.typemod.variable.readonly.scala'] = {},
          ['@lsp.type.namespace.scala'] = { link = '@constant' },

          -- Typescript/Vue
          ['@lsp.mod.readonly.typescript'] = {},
          ['@lsp.mod.defaultLibrary.typescript'] = {},
          ['@lsp.typemod.method.defaultLibrary.vue'] = {},
        },
      }
      vim.cmd 'colorscheme onedark_vivid'
    end,
  },

  {
    'echasnovski/mini.statusline',
    config = function()
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
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      -- TODO: Remove custom definitions, I will always use a nerd font.
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      -- TODO: Remove or update.
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },
}
