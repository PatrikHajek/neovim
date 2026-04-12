-- For C# LSP.

vim.filetype.add {
  extension = {
    -- For Avalonia development.
    -- XML doesn't have textobjects, so using HTML instead.
    axaml = 'html',
  },
}

return {
  'seblyng/roslyn.nvim',
  ---@module 'roslyn.config'
  ---@type RoslynNvimConfig
  opts = {},
}
