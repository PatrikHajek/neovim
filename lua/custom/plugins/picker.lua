return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ['<C-q>'] = require('telescope.actions').smart_send_to_qflist,
              ['<C-x>'] = require('telescope.actions').delete_buffer,
              ['<C-i>'] = require('telescope.actions.layout').toggle_preview,
              ['<C-r>/'] = function()
                local pattern = vim.fn.getreg '/'
                if pattern:match '^\\v' then
                  pattern = pattern:sub(3)
                end
                vim.api.nvim_put({ pattern }, 'c', true, true)
              end,
            },
            n = {
              ['<C-q>'] = require('telescope.actions').smart_send_to_qflist,
              ['<C-x>'] = require('telescope.actions').delete_buffer,
              ['<C-i>'] = require('telescope.actions.layout').toggle_preview,
            },
          },
          vimgrep_arguments = {
            'rg',
            '--follow', -- Follow symbolic links
            '--hidden', -- Search for hidden files
            '--glob=!.git',
            -- INFO: required by telescope
            '--color=never',
            '--no-heading', -- Don't group matches by each file
            '--with-filename', -- Print the file path with the matched lines
            '--line-number', -- Show line numbers
            '--column', -- Show column numbers
            '--smart-case', -- Smart case search
          },
          -- INFO: sets default theme (vertical) for all pickers
          results_title = false,
          sorting_strategy = 'ascending',
          layout_strategy = 'vertical',
          layout_config = {
            prompt_position = 'top',
            preview_cutoff = 1, -- Preview should always show (unless previewer = false)
            vertical = {
              preview_height = function(_, _, max_lines)
                local BORDER = 1
                local QUERY = 1
                local height = (max_lines - 6 * BORDER - QUERY) / 2
                return math.floor(height)
              end,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = {
              'rg',
              '--files',
              '--follow',
              '--hidden',
              '--glob=!.git',
              -- INFO: including `.env` file like this doesn't work
              -- '--glob=.env',
            },
          },
          lsp_dynamic_workspace_symbols = {
            -- INFO: fixed by GitHub [comment](https://github.com/nvim-telescope/telescope.nvim/issues/2104#issuecomment-1223790155)
            sorter = require('telescope').extensions.fzf.native_fzf_sorter(),
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>s:', builtin.commands, { desc = '[S]earch [:] (commands)' })
      vim.keymap.set('n', '<leader>sch', builtin.command_history, { desc = '[S]earch [C]ommand [H]istory' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        local make_entry = require 'telescope.make_entry'
        local entry_display = require 'telescope.pickers.entry_display'

        builtin.live_grep {
          prompt_title = 'Live Grep in Current Buffer',
          search_dirs = { '%' },
          path_display = { 'hidden' },

          entry_maker = function(entry)
            local displayer = entry_display.create {
              separator = ' │ ',
              items = {
                { width = 4 },
                { remaining = true },
              },
            }

            local e = make_entry.gen_from_vimgrep {}(entry)
            e.display = function(ent)
              return displayer {
                ent.lnum,
                ent.text,
              }
            end

            return e
          end,
        }
      end, { desc = '[/] Search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      local pickers = require 'custom.plugins.picker.treesitter'
      local query_files = {
        'highlights',
        'locals',
        'textobjects',
      }

      --- @param annotations string[]
      --- @return function
      local function lua_filter_doc(annotations)
        return function(text)
          for _, annotation in ipairs(annotations) do
            local match_col, match_text = text:match('.*@' .. annotation .. ' ()(%S+)')
            if match_col ~= nil then
              return { text = match_text, col = match_col - 1 }
            end
          end
          return false
        end
      end

      local lua_filter_type = lua_filter_doc { 'class', 'alias' }

      local function lua_filter_elseif(text, col)
        if text:match '^elseif' then
          return { text = text, col = col }
        else
          return false
        end
      end

      local function js_filter_import(text)
        local match_col, match_text = text:match '^import ()(%w+)'
        if match_col then
          return { text = match_text, col = match_col - 1 }
        else
          return false
        end
      end

      local js_filters = { javascript = js_filter_import, typescript = js_filter_import, vue = js_filter_import }

      local function prisma_filter_model(text)
        local match_col, match_text = text:match '%w+ ()(%w+)'
        if match_col then
          return { text = match_text, col = match_col - 1 }
        else
          return false
        end
      end

      --- @type picker.treesitter.Capture[]
      local captures = {
        { kind = 'local.definition.import', name = 'import', hl = '@keyword.import', chars = 100 },
        { kind = 'keyword.import', name = 'import', chars = 100, text = 'full', filters = { 'include', js_filters } },
        { kind = 'module', name = 'module', filters = { 'exclude', { luadoc = true } } },
        { kind = 'class.outer', name = 'type', hl = '@type', chars = 4 },
        { kind = 'comment', name = 'type', hl = '@type', text = 'full', filters = { 'include', { lua = lua_filter_type } } },
        { kind = 'keyword', name = 'type', hl = '@type', text = 'full', filters = { 'include', { prisma = prisma_filter_model } } },
        { kind = 'function', name = 'function' },
        { kind = 'function.method', name = 'method' },
        { kind = 'function.call', name = 'call fn', text = 'preceding' },
        { kind = 'function.method.call', name = 'call mtd', text = 'preceding' },
        { kind = 'keyword.coroutine', name = 'coroutine' },
        { kind = 'loop.outer', name = 'loop', hl = '@keyword.repeat', text = 'full' },
        { kind = 'conditional.outer', name = 'condition', hl = '@keyword.conditional' },
        { kind = 'block.outer', name = 'condition', hl = '@keyword.conditional', text = 'full', filters = { 'include', { lua = lua_filter_elseif } } },
        { kind = 'keyword.conditional.ternary', name = 'cond ternany' },
        { kind = 'label', name = 'label' },
        { kind = 'keyword.exception', name = 'exception' },
        { kind = 'local.definition.var', name = 'variable', hl = '@variable' },
        { kind = 'variable', name = 'variable', hl = '@variable', filters = { 'include', { prisma = true } } },
        { kind = 'variable.parameter', name = 'parameter', chars = 8 },
        { kind = 'local.definition.parameter', name = 'parameter', hl = '@variable.parameter', chars = 8 },
        { kind = 'variable.member', name = 'member', chars = 10 },
        { kind = 'property', name = 'member', hl = '@variable.member', chars = 10 },
        { kind = 'tag', name = 'tag' },
        { kind = 'tag.attribute', name = 'attribute' },
        { kind = 'string.regexp', name = 'regexp', chars = 100 },
        { kind = 'string', name = 'string', chars = 120 },
        { kind = 'comment', name = 'comment', chars = 200 },
        { kind = 'comment.documentation', name = 'documentation', chars = 190 },
      }
      vim.keymap.set('n', '<leader>st', function()
        pickers.treesitter { query_files = query_files, captures = captures }
      end, { desc = '[S]earch [T]reesitter' })
      vim.keymap.set('n', '<leader>sat', function()
        pickers.treesitter { query_files = query_files, captures = {} }
      end, { desc = '[S]earch [A]ll of [T]reesitter' })

      vim.keymap.set('n', '<leader>saf', function()
        require('telescope.builtin').find_files {
          find_command = {
            'rg',
            '--files',
            '--follow',
            '--hidden',
            '--no-ignore',
            '--glob=!.git',
            '--glob=!node_modules',
          },
        }
      end, { desc = '[S]earch [A]ll [F]iles' })
      vim.keymap.set('n', '<leader>sag', function()
        require('telescope.builtin').live_grep {
          additional_args = { '--no-ignore' },
          glob_pattern = { '!node_modules' },
        }
      end, { desc = '[S]earch [A]ll files using [G]rep' })

      ---@param prefix string
      ---@param path string
      ---@param name string
      local function map_search(prefix, path, name)
        vim.keymap.set('n', '<leader>s' .. prefix .. 'f', function()
          require('telescope.builtin').find_files { cwd = vim.fn.expand(path) }
        end, { desc = '[S]earch ' .. name .. ' [F]iles' })
        vim.keymap.set('n', '<leader>s' .. prefix .. 'g', function()
          require('telescope.builtin').live_grep { cwd = vim.fn.expand(path) }
        end, { desc = '[S]earch ' .. name .. ' by [G]rep' })
      end
      map_search('p', '$HOME/notes/', '[P]KM')
      map_search('o', '$HOME/notes-tomake/', '[O]rganization')
      map_search('n', vim.fn.stdpath 'config', '[N]eovim')
    end,
  },
}
