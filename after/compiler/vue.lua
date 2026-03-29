vim.api.nvim_buf_set_var(0, 'current_compiler', 'vue')

vim.opt_local.makeprg = 'pnpm vue-tsc --noEmit'

--@ vue-tsc detects it's running in a shell and formats it's output accordingly.
vim.opt_local.errorformat = [[%f(%l\,%c):\ %trror\ TS%n:\ %m]]
