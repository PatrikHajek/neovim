vim.api.nvim_buf_set_var(0, 'current_compiler', 'cs')

vim.opt_local.makeprg = 'dotnet build'

vim.opt_local.errorformat = {
  [[%f(%l\,%c):\ %trror\ %.%\\+:\ %m]],
  [[%f\ :\ %tarning\ %.%\\+:\ %m]],
}
