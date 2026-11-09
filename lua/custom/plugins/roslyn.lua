-- For C# LSP.

vim.filetype.add {
  extension = {
    -- For Avalonia development.
    -- XML doesn't have textobjects, so using HTML instead.
    axaml = 'html',
  },
}
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.cshtml',
  command = 'set filetype=html',
})

return {
  'seblyng/roslyn.nvim',
  ---@module 'roslyn.config'
  ---@type RoslynNvimConfig
  opts = {},
}
