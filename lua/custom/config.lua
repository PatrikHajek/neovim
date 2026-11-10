--[[
  For printing (debugging) tables, use
  `vim.api.nvim_echo({ { vim.inspect(your_value) } }, false, {})`
  You can then view the whole console using `:messages`.

  INFO: To define a type for a variable you must use `---` instead of `--` for
  the comment.

  INFO: you can search for available values using Telescope's `vim.options`
  picker. You can also search registered autocommands using `autocommands` or
  highlights using `highlights`.
--]]

-- [[ Spellcheck ]]

vim.opt.spell = true
vim.opt.spelllang = 'en_us'
vim.opt.spelloptions = 'camel'
vim.opt.spellcapcheck = ''

-- [[ Visibility ]]

vim.opt.scrolloff = 1000
vim.opt.sidescrolloff = 15
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'

local colorcolumns = {
  default = '80',
  rust = '100',
  lua = '100',
}
vim.api.nvim_create_autocmd('BufRead', {
  callback = function()
    local filetype = vim.bo.filetype
    if colorcolumns[filetype] ~= nil then
      vim.opt.colorcolumn = colorcolumns[filetype]
    else
      vim.opt.colorcolumn = colorcolumns.default
    end
  end,
})

-- [[ Tab ]]

--@ Convert tabs to spaces.
vim.opt.expandtab = true

--@ Set 2 spaces a tab by default.
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

--@ Turn off 4 spaces a tab in markdown files.
vim.g.markdown_recommended_style = 0

-- [[ Terminal ]]

vim.opt.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon0-blinkoff0-TermCursor'
vim.opt.termguicolors = true

-- [[ Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- To make these keymaps less disorienting when zoomed in.
vim.keymap.set({ 'n', 'x' }, '<C-d>', '10j')
vim.keymap.set({ 'n', 'x' }, '<C-u>', '10k')

vim.keymap.set('x', '>', '>gv')
vim.keymap.set('x', '<', '<gv')

-- keep cursor in the middle when searching
vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })

-- Better pasting behavior.
--- Pastes last yank instead of default register, otherwise pastes from the specified one.
--- @param cmd string
--- @param overrides { [string]: string }[] Replace register (key) with register (value).
local function smart_register_action(cmd, overrides)
  return function()
    if overrides[vim.v.register] then
      return overrides[vim.v.register] .. cmd
    else
      return cmd
    end
  end
end
vim.keymap.set({ 'n', 'x' }, 'x', smart_register_action('x', { ['"'] = '"0' }), { expr = true })
vim.keymap.set('x', 's', smart_register_action('s', { ['"'] = '"0' }), { expr = true })
vim.keymap.set({ 'n', 'x' }, 'p', smart_register_action('p', { ['"'] = '"0' }), { expr = true })
vim.keymap.set({ 'n', 'x' }, 'P', smart_register_action('P', { ['"'] = '"0' }), { expr = true })
vim.keymap.set({ 'n', 'x' }, '<leader>p', '""p', { desc = 'Paste register of last command' })
vim.keymap.set({ 'n', 'x' }, '<leader>P', '""P', { desc = 'Paste register of last command' })

vim.keymap.set({ 'n', 'x', 'o' }, '_', '^')

-- vim.keymap.set('n', '<leader>wb', ':w<CR>', { desc = '[W]rite [B]uffer' })
vim.keymap.set('n', '<leader>q', function()
  if vim.wo.diff then
    vim.cmd 'wa'
    vim.defer_fn(function()
      -- Go to the file diff window to reset the cursor to the 'starting' position.
      vim.cmd 'wincmd l | wincmd j'
      -- Go to the git diff window.
      vim.cmd 'wincmd h | wincmd k'
      local is_fugitive = require('custom.utils').is_fugitive()
      if is_fugitive then
        -- Cursor is in a fugitive buffer. Go to the open diff window below and quit.
        vim.cmd 'wincmd j | q'
      end
      -- Quit the remaining diff window.
      vim.cmd 'q'
    end, 100)
    return
  end

  if #vim.api.nvim_list_wins() == 1 then
    local confirm = vim.fn.confirm 'Quit?'
    if confirm ~= 1 then
      return
    end
  end

  vim.cmd ':q'
end, { desc = '[Q]uit' })

---@param preset "num" | "selection" | nil
local function goto_file(preset)
  local line
  local path
  if preset == 'selection' then
    vim.api.nvim_command ':normal! "sy'
    line = vim.fn.getreg 's'
    line = vim.trim(line:gsub('\n', ''))
    path = line
  else
    line = vim.api.nvim_get_current_line()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local search_start = (line:sub(1, cursor_col + 1):find ' [^ ]+$' or 0) + 1
    local line_trimmed = line:sub(search_start)
    if line_trimmed:find '^%(.*%.%w+.*%)' then
      line_trimmed = line_trimmed:sub(2)
    end
    path = line_trimmed:match '^(.*%.%w+)'
  end
  assert(type(line) == 'string', 'line not set')
  assert(type(path) == 'string', 'path not set')

  local is_fugitive = require('custom.utils').is_fugitive()
  if vim.bo.buftype == 'terminal' or is_fugitive then
    if is_fugitive then
      local cwd = require('custom.utils').get_cwd_from_buf()
      local git_root = require('custom.utils').get_git_root(cwd)
      line = git_root .. line
      path = git_root .. path
    end

    vim.api.nvim_command ':q'
  end

  vim.api.nvim_command(':e ' .. path)

  if preset == 'num' then
    local _, last = line:find(path, 0, true)
    if last then
      local tail = line:sub(last + 1, line:len())
      local lnum = tonumber(tail:match '%d+')
      if lnum == nil then
        return
      end
      local col = tonumber(tail:match '%d+%:(%d+)') or 0
      col = col > 0 and col - 1 or 0
      vim.api.nvim_win_set_cursor(0, { lnum, col })
    end
  end
end
vim.keymap.set('n', 'gf', function()
  goto_file 'num'
end, { noremap = true, desc = 'Jump to file under cursor' })
vim.keymap.set('n', 'gF', function()
  goto_file()
end, { noremap = true, desc = 'Jump to file under cursor without cursor position' })
vim.keymap.set('x', 'gf', function()
  goto_file 'selection'
end, { noremap = true, desc = 'Jump to file using current selection' })

-- [[ Buffers ]]
vim.keymap.set('n', '<leader>bd', ':bd<CR>', { desc = '[B]uffer [D]elete' })
require 'custom.commands.unsaved-buffers'
require 'custom.commands.buffer-info'

-- [[ Vim Search ]]
vim.keymap.set('n', '<CR>', function()
  local cursorPos = vim.api.nvim_win_get_cursor(0)
  local word = vim.fn.expand '<cword>'
  if word == '' then
    return
  end
  vim.api.nvim_command('/' .. word)
  vim.api.nvim_win_set_cursor(0, cursorPos)
end, { desc = 'Search word under the cursor' })

vim.keymap.set('x', '<CR>', function()
  local is_visual_block = vim.fn.mode() == '\22'

  local yank_register = vim.fn.getreg '0'
  vim.api.nvim_command ':normal! m0'
  vim.api.nvim_command ':normal! "sy'
  local selection = vim.fn.getreg 's'
  selection = vim.fn.escape(selection, require('custom.utils').CHARS_ESCAPE_MAGIC)

  if is_visual_block then
    local marks = require('custom.utils').get_selection_marks()
    selection = vim.fn.substitute(selection, '\\v\n', ([[.*\\n.{%i}]]):format(marks.start[2]), 'g')
    selection = ('^.{%i}%s.*'):format(marks.start[2], selection)
  else
    selection = vim.fn.substitute(selection, '\\v\n', [[\\n]], 'g')
  end

  selection = '\\v' .. selection
  vim.fn.setreg('/', selection)
  vim.api.nvim_command ':normal! n'
  vim.api.nvim_command ':normal! `0'
  vim.fn.setreg('0', yank_register)
end, { desc = 'Search selected text' })

local function select_search_no_indent()
  local is_visual_block = vim.fn.mode() == '\22'

  local yank_register = vim.fn.getreg '0'
  vim.api.nvim_command ':normal! m0'
  vim.api.nvim_command ':normal! "sy'
  local selection = vim.fn.getreg 's'
  selection = vim.fn.escape(selection, require('custom.utils').CHARS_ESCAPE_MAGIC)

  if is_visual_block then
    selection = vim.fn.substitute(selection, '\\v\n', [[.*\\n\\1]], 'g')
    selection = [[^(.*)]] .. vim.fn.trim(selection, '', 1)
    if selection:find '\\n%.%*$' then
      selection = selection:sub(1, -3)
    end
  else
    local is_fugitive = require('custom.utils').is_fugitive()
    if is_fugitive then
      selection = vim.fn.substitute(selection, '\\v\\s*\n(\\\\\\+|-)?\\s*', [[\\s*\\n[+-]?\\s*]], 'g')
      selection = vim.fn.substitute(selection, [[\v^(\\\+|-)]], '', 'g')
      selection = '[+-]?\\s*' .. vim.fn.trim(selection, '', 1)
      if selection:find '\\n%[%+%-%]%?\\s%*$' then
        selection = selection:sub(1, -9)
      end
    else
      selection = vim.fn.substitute(selection, '\\v\\s*\n\\s*', [[\\s*\\n\\s*]], 'g')
      selection = '\\s*' .. vim.fn.trim(selection, '', 1)
      if selection:find '\\n\\s%*$' then
        selection = selection:sub(1, -4)
      end
    end
  end

  selection = [[\v]] .. selection
  vim.fn.setreg('/', selection)
  vim.api.nvim_command ':normal! n'
  vim.api.nvim_command ':normal! `0'
  vim.fn.setreg('0', yank_register)
end
vim.keymap.set('x', '<leader><CR>', select_search_no_indent, { desc = 'Search selected text ignoring indentation' })
vim.keymap.set('n', '<leader><CR>', function()
  vim.cmd 'normal! m1'
  vim.cmd 'normal! 0vg_'
  select_search_no_indent()
  vim.cmd 'normal! `1'
end, { desc = 'Search line under the cursor ignoring indentation' })

vim.keymap.set('n', '/', '/\\v', { desc = 'Enable very magic for searching', noremap = true })
vim.keymap.set('n', '<leader>br', ':%s///g<Left><Left>', { desc = '[B]uffer [R]eplace' })
vim.keymap.set('v', '<leader>br', ':s///g<Left><Left>', { desc = '[B]uffer [R]eplace in selected lines' })

-- [[ Lines ]]
-- NOTE: `'<` and `'>` specify line number of the first/last line or character
-- of the selection respectively. See help for more info.
--
-- moving lines up/down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { silent = true })
-- copying lines up/down
vim.keymap.set('v', '<C-J>', ":co '<-1<CR>gv=gv", { silent = true })
vim.keymap.set('v', '<C-K>', ":co '><CR>gv=gv", { silent = true })

-- Changing directories
vim.keymap.set('n', '<leader>cdf', function()
  vim.api.nvim_command ':cd %:h'
end, { desc = "[C]hange [D]irectory to the current [F]ile's directory" })
vim.keymap.set('n', '<leader>cdg', function()
  local cwd = require('custom.utils').get_cwd_from_buf()
  local git_root = require('custom.utils').get_git_root(cwd)
  vim.api.nvim_command(':cd ' .. git_root)
end, { desc = '[C]hange [D]irectory to the closest [G]it root' })
vim.keymap.set('n', '<leader>cdl', function()
  vim.api.nvim_command ':cd -'
end, { desc = '[C]hange [D]irectory to the [L]ast directory' })

-- [[ LSP ]]
-- Remove default lsp keymaps.
vim.keymap.del('n', 'gra')
vim.keymap.del('n', 'gri')
vim.keymap.del('n', 'grn')
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'grt')

vim.keymap.set('n', '<leader>rl', ':LspRestart<CR>', { desc = '[R]estart [L]SP' })
