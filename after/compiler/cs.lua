vim.api.nvim_buf_set_var(0, 'current_compiler', 'cs')

--@ Using `--no-restore` to avoid repeated messages.
vim.opt_local.makeprg = 'dotnet build --no-restore'

vim.opt_local.errorformat = {
  [[%f(%l\,%c):\ %trror\ %.%\\+:\ %m]],
  [[%f\ :\ %tarning\ %.%\\+:\ %m]],
}
