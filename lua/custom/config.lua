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

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
-- turns off 4 spaces a tab in markdown files
vim.g.markdown_recommended_style = 0

-- [[ Terminal ]]

vim.opt.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon0-blinkoff0-TermCursor'
vim.opt.termguicolors = true

-- [[ Keymaps ]]

-- better default experience
vim.keymap.set('x', 'p', '"_dP')
vim.keymap.set('x', '"+p', '"_d"+P')
vim.keymap.set({ 'n', 'v' }, 'd', '"_d')
vim.keymap.set({ 'n', 'v' }, 'c', '"_c')
vim.keymap.set('n', 's', '"_s')
vim.keymap.set({ 'n', 'v' }, 'D', '"_D')
vim.keymap.set({ 'n', 'v' }, 'C', '"_C')
vim.keymap.set('n', 'S', '"_S')

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
      local cwd = vim.fn.expand('%:h'):gsub('^fugitive://', ''):gsub('%.git$', '')
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
vim.keymap.set('n', '<leader>bb', '<C-^>', { desc = 'Switch [B]ack to Last [B]uffer' })
vim.keymap.set('n', '<leader>bd', ':bd<CR>', { desc = '[B]uffer [D]elete' })

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

  local default_register = vim.fn.getreg '"'
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
  vim.fn.setreg('"', default_register)
end, { desc = 'Search selected text' })

local function select_search_no_indent()
  local is_visual_block = vim.fn.mode() == '\22'

  local default_register = vim.fn.getreg '"'
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
  vim.fn.setreg('"', default_register)
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

-- keep cursor in the middle when searching
vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })

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

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Git ]]
vim.keymap.set('n', '<leader>gb', ':Telescope git_branches<CR>', { desc = '[G]it [B]ranches' })
vim.keymap.set('n', '<leader>gc', ':Telescope git_commits<CR>', { desc = '[G]it [C]ommits' })
vim.keymap.set('n', '<leader>bc', ':Telescope git_bcommits<CR>', { desc = 'Show [B]uffer [C]ommits' })

-- Changing directories
vim.keymap.set('n', '<leader>cdf', function()
  vim.api.nvim_command ':cd %:h'
end, { desc = "[C]hange [D]irectory to the current [F]ile's directory" })
vim.keymap.set('n', '<leader>cdg', function()
  local cwd = vim.fn.expand '%:h'
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

local function get_servers()
  local vue_language_server_path = vim.fn.expand '$MASON/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'
  return {
    -- formatters
    prettierd = {},
    black = {},
    -- linters
    eslint_d = {},
    shellcheck = {},
    -- servers
    ts_ls = {
      init_options = {
        plugins = {
          {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
          },
        },
      },
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    },
    vue_ls = {},
    cssls = {
      settings = {
        css = { lint = { unknownAtRules = 'ignore' } },
      },
    },
    tailwindcss = {
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'css', 'html' },
    },
    prismals = {},
    jsonls = {},
    html = { filetypes = { 'html', 'twig', 'hbs' } },
    bashls = {
      filetypes = { 'sh' },
    },
    markdown_oxide = {},
    markdownlint = {},
    clangd = {},
    -- java_language_server = {},
    jdtls = {},
    pyright = {},
    rust_analyzer = {},
  }
end

local function go_to_definition()
  vim.lsp.buf.definition {
    on_list = function(opts)
      ---@alias item {filename: string, text: string}[]

      ---@type item
      local items = opts.items

      ---@type item
      local filtered = {}
      for k in pairs(items) do
        local item = items[k]
        if item.filename:find '%.nuxt/components%.d%.ts' or not item.filename:find '%.nuxt' then
          filtered[#filtered + 1] = items[k]
        end
      end

      if #filtered == 0 then
        vim.fn.setloclist(0, items)
        if #items == 1 then
          vim.api.nvim_command ':lfirst'
        elseif #items > 1 then
          require('telescope.builtin').loclist()
        else
          vim.notify 'No definitions found'
        end
        return
      end

      vim.fn.setloclist(0, filtered)
      if #filtered > 1 then
        require('telescope.builtin').loclist()
        return
      end

      local item = filtered[1]
      if item.filename:find '%.nuxt/components%.d%.ts' then
        local filename = item.filename:match '(.+)components%.d%.ts'
        local path = item.text:match 'import%("(.+)"%)'
        local ext = path:match '.+%.(%w+)$'
        local extension = ext == 'vue' and '' or '.d.ts'

        if not path or not filename then
          vim.notify "File path couldn't be extracted"
        else
          vim.api.nvim_command(':e ' .. filename .. path .. extension)
        end
      else
        vim.api.nvim_command ':lfirst'
      end
    end,
  }
end

-- [[ Imported commands ]]
require 'custom.commands.unsaved-buffers'
require 'custom.commands.buffer-info'

return {
  get_servers = get_servers,
  go_to_definition = go_to_definition,
}
