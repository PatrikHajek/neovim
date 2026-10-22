--- Get the commit count difference between target and HEAD.
--- @param target string
--- @return integer
local function get_commit_count(target)
  local cmd = ('git rev-list --count %s..HEAD'):format(target)
  local count = vim.fn.system(cmd):gsub('%s+', '')
  return tonumber(count) or 0
end

--- Get the commit hash.
--- @param commit_index integer Must be greater than or equal to 0.
--- @return string
local function get_commit_diff_hash(commit_index)
  assert(commit_index >= 0, 'There must be at least 1 commit left to open diff.')
  return ('HEAD~%i..HEAD~%i'):format(commit_index + 1, commit_index)
end

--- Get the commit hash.
--- @param commit_index integer
--- @return string
local function get_commit_hash(commit_index)
  return ('HEAD~%i'):format(commit_index)
end

local commit_count --- @type integer
local commit_index --- @type integer

--- Initialize the state.
--- @param target string
local function init(target)
  commit_count = get_commit_count(target)
  commit_index = commit_count - 1
end

--- Open diff against the adjacent commits.
local function open_diff()
  -- TODO: Could possibly use `DiffviewRefresh` for a smoother experience.
  vim.cmd 'DiffviewClose'
  vim.cmd('DiffviewOpen ' .. get_commit_diff_hash(commit_index))
  print(('Commit HEAD~%i / %i'):format(commit_index, commit_count))
end

local function show()
  local hash = get_commit_hash(commit_index)
  -- `-s` suppresses diff.
  vim.cmd('G show -s ' .. hash)
end

local BRANCH_DEFAULT = 'origin/HEAD'

--- @type table<string, fun(args: string[])>
local commands = {
  -- TODO: Add autocomplete for branches here.
  init = function(args)
    -- TODO: Validate?
    local target = args[1] or BRANCH_DEFAULT
    init(target)
  end,

  next = function()
    if commit_index > 0 then
      commit_index = commit_index - 1
      open_diff()
      require('diffview.config').actions.open_commit_log()
    else
      print 'Reached the last commit'
    end
  end,

  prev = function()
    commit_index = commit_index + 1
    open_diff()
    require('diffview.config').actions.open_commit_log()
  end,

  first = function()
    commit_index = commit_count - 1
    open_diff()
    require('diffview.config').actions.open_commit_log()
  end,

  last = function()
    commit_index = 0
    open_diff()
    require('diffview.config').actions.open_commit_log()
  end,

  diff = function()
    open_diff()
  end,

  show = show,
}

init(BRANCH_DEFAULT)

-- TODO: Add good API to force the user to `git pull` and start reviewing from the first commit.
-- TODO: Support count in next and prev commands to skip commits.
-- TODO: Create a telescope git_commits action that uses this logic to diff the chosen commit.
vim.api.nvim_create_user_command('Commit', function(args)
  local command = args.fargs[1]
  if commands[command] ~= nil then
    local command_args = vim.list_slice(args.fargs, 2)
    commands[command](command_args)
  else
    print 'Not a command'
  end
end, {
  desc = 'See introduced changes commit by commit',
  nargs = '*',
  complete = function(lead)
    local cmds = vim.tbl_keys(commands)
    return vim.tbl_filter(function(cmd)
      return vim.startswith(cmd, lead)
    end, cmds)
  end,
})

return {
  {
    'tpope/vim-fugitive',
    config = function()
      vim.keymap.set('n', '<leader>G', ':tab Git<CR> | 5G_', { desc = 'Open [G]it' })

      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = { 'fugitive://*' },
        callback = function(ev)
          vim.keymap.set('n', '<C-j>', function()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            local lines = vim.api.nvim_buf_get_lines(0, row - 1, -1, false)

            for i, line in ipairs(vim.list_slice(lines, 2, #lines)) do
              -- Due to `lines` including the previous line which is skipped, `i` points to it.
              local line_prev = lines[i]
              local is_hunk_edge = line:find '^[+-]' and (not line_prev or not line_prev:find '^[+-]')
              if is_hunk_edge then
                vim.cmd('normal!' .. row + i .. 'G')
                vim.cmd('normal!' .. col + 1 .. '|')
                return
              end
            end
          end)
          vim.keymap.set('n', '<C-k>', function()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)

            for i = #lines - 1, 1, -1 do
              local line = lines[i]
              local line_next = lines[i + 1]
              local is_hunk_edge = line:find '^[+-]' and (not line_next or not line_next:find '^[+-]')
              if is_hunk_edge then
                vim.cmd('normal!' .. row - (#lines - i) .. 'G')
                vim.cmd('normal!' .. col + 1 .. '|')
                return
              end
            end
          end)

          vim.keymap.set({ 'n', 'x' }, '_', function()
            local line = vim.api.nvim_get_current_line()
            --- @type string | nil
            local line_trimmed = line:match '^[AMRD+-] *(.+)'
            if not vim.wo.diff and line_trimmed then
              --- @type string
              local char = line_trimmed:sub(1, 1)
              vim.api.nvim_command(':normal 0f' .. char)
            else
              vim.api.nvim_command ':normal! _'
            end
          end, { buffer = ev.buf })
        end,
      })

      vim.api.nvim_create_autocmd('WinNew', {
        pattern = 'fugitive://*',
        callback = function()
          vim.schedule(function()
            if vim.wo.diff then
              local TAB_BAR_HEIGHT = 1
              local STATUSLINE_HEIGHT = 1
              local BUFFER_PATH_HEIGHT = 1
              local FUGITIVE_HEIGHT = 1
              local height = vim.o.lines - TAB_BAR_HEIGHT - STATUSLINE_HEIGHT - vim.o.cmdheight - BUFFER_PATH_HEIGHT * 2 - FUGITIVE_HEIGHT
              -- Go to the top window - fugitive buffer.
              vim.cmd 'wincmd t'
              vim.api.nvim_win_set_height(0, FUGITIVE_HEIGHT)
              vim.cmd 'wincmd j'
              vim.api.nvim_win_set_height(0, math.floor(height / 2))
              vim.cmd 'wincmd j'
              vim.api.nvim_win_set_height(0, math.ceil(height / 2))
            end
          end)
        end,
      })
    end,
  },
  'tpope/vim-rhubarb',

  {
    'sindrets/diffview.nvim',
    -- TODO: Make LSPs work in the main diff buffer. Either the buffer use the actual file or change
    -- LSP config to run in that buffer.
    dependencies = {
      'lewis6991/gitsigns.nvim',
    },
    config = function()
      vim.keymap.set('n', '<leader>hDa', ':DiffviewOpen<CR>', { desc = 'Diff against index (show (un)staged hunks)' })

      local actions = require('diffview.config').actions

      local keymaps_global = {
        { 'n', '<leader>e', actions.toggle_files, { desc = 'Toggle files' } },
        { 'n', '<leader>b', false },

        -- custom
        { 'n', '<leader>q', ':wa | DiffviewClose<CR>', { desc = 'Save all buffers and quit' } },
      }

      require('diffview').setup {
        hooks = {
          --@ Attach gitsigns to the buffers.
          diff_buf_read = function(buf)
            local name = vim.api.nvim_buf_get_name(buf)
            -- Skip as gitsigns will attach automatically to the real file.
            if not vim.startswith(name, 'diffview') then
              return
            end

            vim.defer_fn(function()
              local gitsigns = require 'gitsigns'

              local staged_file = name:match '%.git/:0:/(.+)'
              if staged_file then
                gitsigns.attach(buf, { file = staged_file, base = 'HEAD' })
              end

              local commit, path = name:match '%.git/([^/]+)/(.+)'
              if commit and path then
                local parent = vim.fn.system('git rev-parse ' .. commit .. '^'):gsub('%s+', '')
                gitsigns.attach(buf, { file = path, base = parent })
              end
            end, 100)
          end,
        },

        view = {
          default = {
            layout = 'diff2_vertical',
          },
        },

        keymaps = {
          view = keymaps_global,
          file_panel = vim.list_extend(keymaps_global, {
            { 'n', 'h', false },
            { 'n', 'j', false },
            { 'n', 'k', false },
            { 'n', 'l', false },
            {
              'n',
              '=',
              function()
                local pos = vim.api.nvim_win_get_cursor(0)
                actions.toggle_fold()
                vim.api.nvim_win_set_cursor(0, pos)
              end,
              { desc = 'Toggle fold' },
            },
            -- {
            --   'n',
            --   '<CR>',
            --   function()
            --     actions.select_entry()
            --     actions.toggle_files()
            --   end,
            --   { desc = 'Jump to the diff for the selected entry' },
            -- },
          }),
        },
      }
    end,
  },
}
