--- Keeps track of the last open Trouble mode.
local trouble_mode = 'qflist'

--- Toggle Trouble window. If mode is omitted, use the last open Trouble mode.
--- @param mode string?
local function trouble_toggle(mode)
  local trouble = require 'trouble'
  if vim.bo.filetype == 'trouble' then
    trouble.close()
  else
    if mode then
      trouble_mode = mode
    end
    trouble.open(trouble_mode)
  end
end

--- Delete items from Trouble quickfix window.
--- @param ids string[] List of item ids to be deleted.
local function delete(ids)
  local trouble = require 'trouble'

  --- @param item trouble.Item
  local items = vim.tbl_filter(function(item)
    return not vim.list_contains(ids, item.id)
  end, trouble.get_items())

  --- @param item trouble.Item
  --- @type vim.quickfix.entry[]
  local qf_entries = vim.tbl_map(function(item)
    return item.item
  end, items)
  vim.fn.setqflist(qf_entries, 'r')
  trouble.refresh()
end

return {
  {
    'folke/trouble.nvim',
    dependencies = {
      'kiyoon/repeatable-move.nvim',
    },
    cmd = 'Trouble',
    --- @type trouble.Config
    opts = {
      focus = true,
      formatters = {
        diagnostic_icon = function(ctx)
          local type = ctx.item.item.type:lower()
          local severities = {
            e = { text = 'E', hl = 'DiagnosticSignError' },
            w = { text = 'W', hl = 'DiagnosticSignWarn' },
            h = { text = 'H', hl = 'DiagnosticSignHint' },
            n = { text = 'H', hl = 'DiagnosticSignHint' },
            i = { text = 'I', hl = 'DiagnosticSignInfo' },
          }
          return severities[type] or '?'
        end,
      },
      modes = {
        qflist = {
          -- More info in the [source](https://github.com/folke/trouble.nvim/blob/bd67efe408d4816e25e8491cc5ad4088e708a69a/lua/trouble/sources/lsp.lua#L112).
          title = '{hl:Title} QuickFix {hl} {count}',
        },
        qf_references = {
          mode = 'qflist',
          title = '{hl:Title} References {hl} {count}',
        },
        qf_make = {
          mode = 'qflist',
          title = '{hl:Title} Make {hl} {count}',
          format = '{diagnostic_icon} {text:md} {pos}',
        },
        qf_diagnostics = {
          mode = 'qflist',
          title = '{hl:Title} Diagnostics {hl} {count}',
          format = '{diagnostic_icon} {text:md} {pos}',
        },
        -- Can be used to include the item the cursor is on in lsp_references window.
        -- lsp_base = {
        --   params = {
        --     include_current = true,
        --   },
        -- },
      },
      preview = { scratch = false },
      keys = {
        ['<esc>'] = false,
        ['<cr>'] = 'jump_close',
        ['='] = 'fold_toggle',
        ['gf'] = {
          action = function()
            vim.cmd 'q'
            vim.cmd 'cfirst'
          end,
          desc = 'Close and jump to the first item',
        },
        ['c'] = {
          action = function(view)
            if view.opts.mode == 'diagnostics' then
              local items = require('trouble').get_items()
              vim.fn.setqflist(vim.diagnostic.toqflist(items), ' ')
              vim.api.nvim_command ':q'
            elseif view.opts.mode == 'lsp_references' then
              vim.api.nvim_command ':q'
              vim.lsp.buf.references(nil, {
                on_list = function(options)
                  --- This is done per documentation: `:help vim.lsp.listOpts`.
                  --- @diagnostic disable-next-line: param-type-mismatch
                  vim.fn.setqflist({}, 'r', options)
                end,
              })
            else
              print "Doesn't work for any other modes than diagnostics and lsp_references!"
            end
          end,
          desc = 'Send items to quickfix list and close the window',
        },
        ['d'] = {
          --- @param view trouble.View
          action = function(view)
            if not vim.startswith(view.opts.mode, 'qf') then
              print 'Deletions only work in quickfix windows!'
              return
            end

            local selection = view:selection()
            --- @type string[]
            local ids = {}
            for _, node in ipairs(selection) do
              --- @param item trouble.Item
              local item_ids = vim.tbl_map(function(item)
                return item.id
              end, node:flatten())
              vim.list_extend(ids, item_ids)
            end

            delete(ids)
          end,
          desc = 'Delete selected nodes',
        },
        ['dd'] = {
          --- @param view trouble.View
          action = function(view)
            if not vim.startswith(view.opts.mode, 'qf') then
              print 'Deletions only work in quickfix windows!'
              return
            end

            local at = view:at()
            if at.node ~= nil then
              --- @param item trouble.Item
              local item_ids = vim.tbl_map(function(item)
                return item.id
              end, at.node:flatten())
              delete(item_ids)
            else
              print "Couldn't get current node"
            end
          end,
          desc = 'Delete the node under the cursor',
        },
      },
    },
    init = function()
      -- [[ Quickfix ]]
      vim.keymap.set('n', '<leader>cf', ':cfirst<CR>', { desc = 'Qui[C]kfix: Go to [F]irst item' })
      vim.keymap.set('n', '<leader>cl', ':clast<CR>', { desc = 'Qui[C]kfix: Go to [L]ast item' })
      vim.keymap.set('n', '<C-l>', ':cnext<CR>', { desc = 'Qui[C]kfix: Go to next item' })
      vim.keymap.set('n', '<C-h>', ':cprev<CR>', { desc = 'Qui[C]kfix: Go to prev item' })

      vim.keymap.set('n', '<leader>co', trouble_toggle, { desc = 'Qui[C]kfix: [O]pen' })

      vim.keymap.set('n', '<leader>lr', function()
        vim.lsp.buf.references(nil, {
          on_list = function(o)
            --- This is done per documentation: `:help vim.lsp.listOpts`.
            --- @diagnostic disable-next-line: param-type-mismatch
            vim.fn.setqflist({}, 'r', o)
            trouble_toggle 'qf_references'
          end,
        })
      end, { desc = '[L]ist [R]eferences' })

      vim.keymap.set('n', '<leader>lh', function()
        require('gitsigns').setqflist 'all'
      end, { desc = '[L]ist [H]unks' })

      vim.keymap.set('n', '<leader>vg', ':vimgrep //gj ', { desc = '[V]im[G]rep' })
      vim.keymap.set('n', '<leader>vr', ':cdo s//', { desc = '[V]im [R]eplace' })

      vim.cmd 'packadd cfilter'
      vim.api.nvim_create_user_command('Crefine', function(args)
        local command = args.bang and 'Cfilter!' or 'Cfilter'
        local arg = #args.fargs == 1 and args.fargs[1] or vim.fn.getreg '/'
        vim.cmd(command .. ' ' .. arg)
        require('trouble').refresh()
      end, { bang = true, nargs = '?', desc = 'Calls Cfilter and refreshes trouble window' })

      vim.keymap.set('n', '<leader>cs', ':Telescope quickfix<CR>', { desc = 'Qui[C]kfix: [S]earch items' })
      vim.keymap.set('n', '<leader>ch', ':Telescope quickfixhistory<CR>', { desc = 'Qui[C]kfix: Search [H]istory' })

      -- [[ Diagnostics ]]
      vim.keymap.set('n', '?', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })

      local diagnostic_next, diagnostic_prev = require('repeatable_move').make_repeatable_move_pair(function()
        vim.diagnostic.jump { count = 1, float = true }
      end, function()
        vim.diagnostic.jump { count = -1, float = true }
      end)
      vim.keymap.set('n', ']d', diagnostic_next, { desc = 'Next diagnostic' })
      vim.keymap.set('n', '[d', diagnostic_prev, { desc = 'Previous diagnostic' })

      vim.keymap.set('n', '<leader>ld', function()
        local diagnostics = vim.diagnostic.get()
        local items = {}
        for _, d in ipairs(diagnostics) do
          local item = vim.diagnostic.toqflist({ d })[1]
          item.text = ('%s [%s] %s'):format(item.text, d.code, d.source)
          table.insert(items, item)
        end
        vim.fn.setqflist(items, ' ')
        trouble_toggle 'qf_diagnostics'
      end, { desc = '[L]ist [D]iagnostics' })
    end,
  },

  {
    'tpope/vim-dispatch',
    cmd = { 'Dispatch', 'Make', 'Focus', 'Start' }, -- Or lazy-load on these commands
    init = function()
      vim.g.dispatch_no_maps = 1

      --- List of compiler pipelines. Each pipeline runs it's compilers in the order of definition.
      --- @type { name: string, compilers: string[] }[]
      local pipelines = {
        { name = 'nuxi + eslint', compilers = { 'nuxi', 'eslint' } },
        { name = 'vue + eslint', compilers = { 'vue', 'eslint' } },
      }

      vim.api.nvim_create_autocmd('QuickFixCmdPost', {
        pattern = '[m]ake',
        callback = function()
          -- Default quickfix list takes a little while to open.
          vim.schedule(function()
            vim.cmd 'cclose'
          end)
          trouble_toggle 'qf_make'
        end,
      })

      local function pick_compiler()
        local pickers = require 'telescope.pickers'
        local finders = require 'telescope.finders'
        local conf = require('telescope.config').values
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'

        local options = {}
        vim.list_extend(options, pipelines)
        local compilers = vim.fn.getcompletion('', 'compiler')
        for _, v in ipairs(compilers) do
          table.insert(options, { name = v, compilers = { v } })
        end

        table.sort(options, function(a, b)
          return a.name:lower() < b.name:lower()
        end)

        pickers
          .new({}, {
            prompt_title = 'Select Compiler',
            finder = finders.new_table {
              results = options,
              entry_maker = function(entry)
                return { display = entry.name, value = entry, ordinal = entry.name }
              end,
            },
            sorter = conf.generic_sorter {},
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry().value

                local combined_prg = {}
                local combined_efm = {}

                for _, c in ipairs(selection.compilers) do
                  -- After calling `:compiler <name>`, errorformat and makeprg are set.
                  vim.cmd('compiler ' .. c)
                  table.insert(combined_prg, vim.bo.makeprg)
                  vim.list_extend(combined_efm, vim.opt_local.errorformat:get())
                end

                --@ `&` runs commands in parallel. Since both compilers write to stdout, this might
                --@ break the output if they finish at the same time.
                vim.opt_local.makeprg = table.concat(combined_prg, ' & ') .. ' & wait'
                vim.opt_local.errorformat = combined_efm

                vim.cmd 'Make'
                -- Close the output buffer opened by default.
                vim.cmd 'cclose'
                print('Compiling using ' .. selection.name)
              end)
              return true
            end,
          })
          :find()
      end
      vim.keymap.set('n', '<leader>cm', pick_compiler, { desc = 'Qui[C]kfix: Run [M]ake' })
    end,
  },
}
